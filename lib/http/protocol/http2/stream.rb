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
			#                          +--------+
			#                  send PP |        | recv PP
			#                 ,--------|  idle  |--------.
			#                /         |        |         \
			#               v          +--------+          v
			#        +----------+          |           +----------+
			#        |          |          | send H /  |          |
			# ,------| reserved |          | recv H    | reserved |------.
			# |      | (local)  |          |           | (remote) |      |
			# |      +----------+          v           +----------+      |
			# |          |             +--------+             |          |
			# |          |     recv ES |        | send ES     |          |
			# |   send H |     ,-------|  open  |-------.     | recv H   |
			# |          |    /        |        |        \    |          |
			# |          v   v         +--------+         v   v          |
			# |      +----------+          |           +----------+      |
			# |      |   half   |          |           |   half   |      |
			# |      |  closed  |          | send R /  |  closed  |      |
			# |      | (remote) |          | recv R    | (local)  |      |
			# |      +----------+          |           +----------+      |
			# |           |                |                 |           |
			# |           | send ES /      |       recv ES / |           |
			# |           | send R /       v        send R / |           |
			# |           | recv R     +--------+   recv R   |           |
			# | send R /  `----------->|        |<-----------'  send R / |
			# | recv R                 | closed |               recv R   |
			# `----------------------->|        |<----------------------'
			#                          +--------+
			# 
			#    send:   endpoint sends this frame
			#    recv:   endpoint receives this frame
			# 
			#    H:  HEADERS frame (with implied CONTINUATIONs)
			#    PP: PUSH_PROMISE frame (with implied CONTINUATIONs)
			#    ES: END_STREAM flag
			#    R:  RST_STREAM frame
			#
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
				end
				
				def write_frame(frame)
					@connection.write_frame(frame)
				end
				
				def closed?
					@state == :closed
				end
				
				private def write_headers(priority, headers, flags = 0)
					data = @connection.encode_headers(headers)
					
					frame = HeadersFrame.new(@id, flags)
					frame.pack(priority, data, maximum_size: @connection.maximum_frame_size)
					
					write_frame(frame)
					
					return frame
				end
				
				def send_headers(*args)
					if @state == :idle
						frame = write_headers(*args)
						
						if frame.end_stream?
							@state = :half_closed_local
						else
							@state = :open
						end
					elsif @state == :half_closed_remote
						frame = write_headers(*args)
						
						if frame.end_stream?
							@state = :closed
						end
					else
						raise ProtocolError, "Cannot send headers in state: #{@state}"
					end
				end
				
				private def write_data(data, flags = 0, **options)
					frame = DataFrame.new(@id, flags)
					frame.pack(data, **options)
					write_frame(frame)
					
					return frame
				end
				
				def send_data(*args)
					if @state == :open
						frame = write_data(*args)
						
						if frame.end_stream?
							@state = :half_closed_local
						end
					elsif @state == :half_closed_remote
						frame = write_data(*args)
						
						if frame.end_stream?
							@state = :closed
						end
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
						
						@state = :closed
					else
						raise ProtocolError, "Cannot reset stream in state: #{@state}"
					end
				end
				
				def active!
					@state = :active
				end
				
				def half_closed!
					@state = :half_closed
				end
				
				def closed!
					@state = :closed
				end
				
				private def process_headers(frame)
					# Receiving request headers:
					priority, data = frame.unpack
					
					if priority
						@priority = priority
					end
					
					return @connection.decode_headers(data)
				end
				
				def receive_headers(frame)
					if @state == :idle
						if frame.end_stream?
							@state = :half_closed_remote
						else
							@state = :open
						end
						
						return process_headers(frame)
					elsif @state == :half_closed_local
						if frame.end_stream?
							@state = :closed
						end
						
						return process_headers(frame)
					else
						raise ProtocolError, "Cannot receive headers in state: #{@state}"
					end
				end
				
				def receive_data(frame)
					if @state == :open
						if frame.end_stream?
							@state = :half_closed_remote
						end
						
						return frame.unpack
					elsif @state == :half_closed_local
						if frame.end_stream?
							@state = :closed
						end
						
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
