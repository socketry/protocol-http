# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'ping_frame'

module HTTP
	module Protocol
		module HTTP2
			class Settings
				MAXIMUM_ALLOWED_WINDOW_SIZE = 0x7FFFFFFF
				MAXIMUM_ALLOWED_FRAME_SIZE = 0xFFFFFF
				
				HEADER_TABLE_SIZE = 0x1
				ENABLE_PUSH = 0x2
				MAXIMUM_CONCURRENT_STREAMS = 0x3
				INITIAL_WINDOW_SIZE = 0x4
				MAXIMUM_FRAME_SIZE = 0x5
				MAXIMUM_HEADER_LIST_SIZE = 0x6
				
				# Allows the sender to inform the remote endpoint of the maximum size of the header compression table used to decode header blocks, in octets.
				attr_accessor :header_table_size
				
				# This setting can be used to disable server push. An endpoint MUST NOT send a PUSH_PROMISE frame if it receives this parameter set to a value of 0.
				attr :enable_push
				
				def enable_push= value
					if @enable_push == 0 || @enable_push == 1
						@enable_push = value
					else
						raise ProtocolError, "Invalid value for enable_push: #{value}"
					end
				end
				
				def enable_push?
					@enable_push != 0
				end
				
				# Indicates the maximum number of concurrent streams that the sender will allow.
				attr_accessor :maximum_concurrent_streams
				
				# Indicates the sender's initial window size (in octets) for stream-level flow control.
				attr :initial_window_size
				
				def initial_window_size= value
					if value < MAXIMUM_ALLOWED_WINDOW_SIZE
						@initial_window_size = value
					else
						raise FlowControlError, "Invalid value for initial_window_size: #{value} > #{MAXIMUM_ALLOWED_WINDOW_SIZE}"
					end
				end
				
				# Indicates the size of the largest frame payload that the sender is willing to receive, in octets.
				attr :maximum_frame_size
				
				def maximum_frame_size= value
					if value < MAXIMUM_ALLOWED_FRAME_SIZE
						@maximum_frame_size = value
					else
						raise ProtocolError, "Invalid value for maximum_frame_size: #{value} > #{MAXIMUM_ALLOWED_FRAME_SIZE}"
					end
				end
				
				# This advisory setting informs a peer of the maximum size of header list that the sender is prepared to accept, in octets.
				attr_accessor :maximum_header_list_size
				
				def initialize
					# These limits are taken from the RFC:
					# https://tools.ietf.org/html/rfc7540#section-6.5.2
					@header_table_size = 4096
					@enable_push = 1
					@maximum_concurrent_streams = 0xFFFFFFFF
					@initial_window_size = 0xFFFF # 2**16 - 1
					@maximum_frame_size = 0x3FFF # 2**14 - 1
					@maximum_header_list_size = 0xFFFFFFFF
				end
				
				ASSIGN = [
					nil,
					:header_table_size=,
					:enable_push=,
					:maximum_concurrent_streams=,
					:initial_window_size=,
					:maximum_frame_size=,
					:maximum_header_list_size=,
				]
				
				def update(changes)
					changes.each do |key, value|
						if name = ASSIGN[key]
							self.send(name, value)
						end
					end
				end
				
				def difference(other)
					changes = []
					
					if @header_table_size != other.header_table_size
						changes << [HEADER_TABLE_SIZE, @header_table_size]
					end
					
					if @enable_push != other.enable_push
						changes << [ENABLE_PUSH, @enable_push ? 1 : 0]
					end
					
					if @maximum_concurrent_streams != other.maximum_concurrent_streams
						changes << [MAXIMUM_CONCURRENT_STREAMS, @maximum_concurrent_streams]
					end
					
					if @initial_window_size != other.initial_window_size
						changes << [INITIAL_WINDOW_SIZE, @initial_window_size]
					end
					
					if @maximum_frame_size != other.maximum_frame_size
						changes << [MAXIMUM_FRAME_SIZE, @maximum_frame_size]
					end
					
					if @maximum_header_list_size != other.maximum_header_list_size
						changes << [MAXIMUM_HEADER_LIST_SIZE, @maximum_header_list_size]
					end
					
					return changes
				end
			end
			
			class PendingSettings
				def initialize(current = Settings.new)
					@current = current
					@pending = current.dup
					
					@queue = []
				end
				
				attr :current
				attr :pending
				
				def append(changes)
					@queue << changes
					@pending.update(changes)
				end
				
				def acknowledge
					if changes = @queue.shift
						@current.update(changes)
					else
						raise ProtocolError.new("Cannot acknowledge settings, no changes pending")
					end
				end
				
				def header_table_size
					@current.header_table_size
				end
				
				def enable_push
					@current.enable_push
				end
				
				def maximum_concurrent_streams
					@current.maximum_concurrent_streams
				end
				
				def initial_window_size
					@current.initial_window_size
				end
				
				def maximum_frame_size
					@current.maximum_frame_size
				end
				
				def maximum_header_list_size
					@current.maximum_header_list_size
				end
			end
			
			# The SETTINGS frame conveys configuration parameters that affect how endpoints communicate, such as preferences and constraints on peer behavior. The SETTINGS frame is also used to acknowledge the receipt of those parameters. Individually, a SETTINGS parameter can also be referred to as a "setting".
			# 
			# +-------------------------------+
			# |       Identifier (16)         |
			# +-------------------------------+-------------------------------+
			# |                        Value (32)                             |
			# +---------------------------------------------------------------+
			#
			class SettingsFrame < Frame
				TYPE = 0x4
				FORMAT = "nN".freeze
				
				include Acknowledgement
				
				def connection?
					true
				end
				
				def unpack
					super.scan(/....../).map{|s| s.unpack(FORMAT)}
				end
				
				def pack(settings = [])
					super settings.map{|s| s.pack(FORMAT)}.join
				end
				
				def apply(connection)
					connection.receive_settings(self)
				end
				
				def read_payload(io)
					super
					
					if @stream_id != 0
						raise ProtocolError, "Settings apply to connection only, but stream_id was given"
					end
					
					if acknowledgement? and @length != 0
						raise FrameSizeError, "Settings acknowledgement must not contain payload: #{@payload.inspect}"
					end
					
					if (@length % 6) != 0
						raise FrameSizeError, "Invalid frame length"
					end
				end
			end
		end
	end
end
