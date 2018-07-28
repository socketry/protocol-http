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

require_relative 'connection'

module HTTP
	module Protocol
		module HTTP2
			# A single HTTP 2.0 connection can multiplex multiple streams in parallel:
			# multiple requests and responses can be in flight simultaneously and stream
			# data can be interleaved and prioritized.
			#
			# This class encapsulates all of the state, transition, flow-control, and
			# error management as defined by the HTTP 2.0 specification. All you have
			# to do is subscribe to appropriate events (marked with ":" prefix in
			# diagram below) and provide your application logic to handle request
			# and response processing.
			#
			#                         +--------+
			#                    PP   |        |   PP
			#                ,--------|  idle  |--------.
			#               /         |        |         \
			#              v          +--------+          v
			#       +----------+          |           +----------+
			#       |          |          | H         |          |
			#   ,---|:reserved |          |           |:reserved |---.
			#   |   | (local)  |          v           | (remote) |   |
			#   |   +----------+      +--------+      +----------+   |
			#   |      | :active      |        |      :active |      |
			#   |      |      ,-------|:active |-------.      |      |
			#   |      | H   /   ES   |        |   ES   \   H |      |
			#   |      v    v         +--------+         v    v      |
			#   |   +-----------+          |          +-----------+  |
			#   |   |:half_close|          |          |:half_close|  |
			#   |   |  (remote) |          |          |  (local)  |  |
			#   |   +-----------+          |          +-----------+  |
			#   |        |                 v                |        |
			#   |        |    ES/R    +--------+    ES/R    |        |
			#   |        `----------->|        |<-----------'        |
			#   | R                   | :close |                   R |
			#   `-------------------->|        |<--------------------'
			#                         +--------+
			class Stream
				# Stream ID (odd for client initiated streams, even otherwise).
				attr :id

				# Stream state as defined by HTTP 2.0.
				attr :state

				# Request parent stream of push stream.
				attr :parent

				# Stream priority as set by initiator.
				attr :weight
				attr :dependency

				# Size of current stream flow control window.
				attr :local_window
				attr :remote_window
				alias window local_window

				def initialize(connection, id = connection.next_stream_id)
					@connection = connection
					@id = id
					
					@state = :idle
					
					@priority = nil
					@headers = []
				end
				
				attr :headers
				
				def write_frame(frame)
					@connection.write_frame(frame)
				end
				
				def closed?
					@state == :closed
				end
				
				def send_headers(priority, headers, flags = 0)
					if @state == :idle
						data = @connection.encode_headers(headers)
						
						frame = HeadersFrame.new(@id, flags)
						frame.pack(priority, data, maximum_size: @connection.maximum_frame_size)
						
						write_frame(frame)
						
						if frame.end_stream?
							@state = :half_closed
						else
							@state = :active
						end
					else
						raise ProtocolError, "Cannot send headers in state: #{@state}"
					end
				end
				
				def send_data(data, flags = 0)
					if @state == :active
						frame = DataFrame.new(@id, flags)
						frame.pack(data)
						
						write_frame(frame)
					else
						raise ProtocolError, "Cannot send data in state: #{@state}"
					end
				end
				
				def send_reset_stream(error_code = 0)
					if @state != :idle and @state != :closed
						frame = ResetStreamFrame.new(@id)
						frame.pack(error_code)
						
						# Clear any unsent frames?
						
						write_frame(frame)
					else
						raise ProtocolError, "Cannot reset stream in state: #{@state}"
					end
				end
				
				def update_active_state(frame)
					if frame.end_stream?
						@state = :half_closed
					else
						@state = :active
					end
				end
				
				def receive_headers(frame)
					if @state == :idle
						@priority, data = frame.unpack
						
						headers = @connection.decode_headers(data)
						
						@headers += headers
						
						update_active_state(frame)
						
						return headers
					else
						raise ProtocolError, "Cannot receive headers in state: #{@state}"
					end
				end
				
				def receive_data(frame)
					if @state == :active
						update_active_state(frame)
						
						return frame.unpack
					else
						raise ProtocolError, "Cannot receive data in state: #{@state}"
					end
				end
				
				def receive_priority(frame)
					@priority = frame.unpack
				end
				
				def receive_reset_stream(frame)
					if @state != :idle and @state != :closed
						@state = :closed
						
						return frame.unpack
					else
						raise ProtocolError, "Cannot reset stream in state: #{@state}"
					end
				end
			end
		end
	end
end
