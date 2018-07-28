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
				HEADER_TABLE_SIZE = 0x1
				ENABLE_PUSH = 0x2
				MAX_CONCURRENT_STREAMS = 0x3
				INITIAL_WINDOW_SIZE = 0x4
				MAX_FRAME_SIZE = 0x5
				MAX_HEADER_LIST_SIZE = 0x6
				
				# Allows the sender to inform the remote endpoint of the maximum size of the header compression table used to decode header blocks, in octets.
				attr_accessor :header_table_size
				
				# This setting can be used to disable server push. An endpoint MUST NOT send a PUSH_PROMISE frame if it receives this parameter set to a value of 0.
				attr_accessor :enable_push
				
				# Indicates the maximum number of concurrent streams that the sender will allow.
				attr_accessor :max_concurrent_streams
				
				# Indicates the sender's initial window size (in octets) for stream-level flow control.
				attr_accessor :initial_window_size
				
				# Indicates the size of the largest frame payload that the sender is willing to receive, in octets.
				attr_accessor :max_frame_size
				
				# This advisory setting informs a peer of the maximum size of header list that the sender is prepared to accept, in octets.
				attr_accessor :max_header_list_size
				
				def initialize
					@header_table_size = 4096
					@enable_push = 1
					@max_concurrent_streams = 128
					@initial_window_size = 2**16 - 1
					@max_frame_size = 2**14
					@max_header_list_size = 0xFFFFFFFF
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
				TYPE = 0x6
				FORMAT = "nN".freeze
				
				include Acknowledgement
				
				def connection?
					true
				end
				
				def unpack
					super.scan(/....../).map{|s| s.unpack(FORMAT)}
				end
				
				def pack(settings)
					super settings.map{|s| s.pack(FORMAT)}.join
				end
				
				def apply(connection)
					connection.receive_settings(self)
				end
				
				def read_payload(io)
					super
					
					if (@length % 6) != 0
						raise FrameSizeError, "Invalid frame length"
					end
				end
			end
		end
	end
end
