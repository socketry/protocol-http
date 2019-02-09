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
require_relative 'flow_control'

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
				include FlowControl
				
				def initialize(connection, id = connection.next_stream_id)
					@connection = connection
					@id = id
					
					@connection.streams[@id] = self
					
					@state = :idle
					
					@priority = nil
					@local_window = Window.new(connection.local_settings.initial_window_size)
					@remote_window = Window.new(connection.remote_settings.initial_window_size)
					
					@headers = nil
					@data = nil
				end
				
				# Stream ID (odd for client initiated streams, even otherwise).
				attr :id

				# Stream state as defined by HTTP 2.0.
				attr :state
				
				attr :headers
				attr :data
				
				attr :local_window
				attr :remote_window
				
				def maximum_frame_size
					@connection.available_frame_size
				end
				
				def write_frame(frame)
					@connection.write_frame(frame)
				end
				
				def closed?
					@state == :closed or @state == :reset
				end
				
				def send_headers?
					@state == :idle or @state == :reserved_local or @state == :open or @state == :half_closed_remote
				end
				
				def send_failure(status, reason)
					if send_headers?
						send_headers(nil, [
							[':status', status.to_s],
							['reason', reason]
						], END_STREAM)
					else
						send_reset_stream(PROTOCOL_ERROR)
					end
				end
				
				private def write_headers(priority, headers, flags = 0)
					data = @connection.encode_headers(headers)
					
					frame = HeadersFrame.new(@id, flags)
					frame.pack(priority, data, maximum_size: @connection.maximum_frame_size)
					
					write_frame(frame)
					
					return frame
				end
				
				#The HEADERS frame is used to open a stream, and additionally carries a header block fragment.  HEADERS frames can be sent on a stream in the "idle", "reserved (local)", "open", or "half-closed (remote)" state.
				def send_headers(*args)
					if @state == :idle
						frame = write_headers(*args)
						
						if frame.end_stream?
							@state = :half_closed_local
						else
							@state = :open
						end
					elsif @state == :reserved_local
						frame = write_headers(*args)
						
						@state = :half_closed_remote
					elsif @state == :open
						frame = write_headers(*args)
						
						if frame.end_stream?
							@state = :half_closed_local
						end
					elsif @state == :half_closed_remote
						frame = write_headers(*args)
						
						if frame.end_stream?
							close!
						end
					else
						raise ProtocolError, "Cannot send headers in state: #{@state}"
					end
				end
				
				def consume_remote_window(frame)
					super
					
					@connection.consume_remote_window(frame)
				end
				
				private def write_data(data, flags = 0, **options)
					frame = DataFrame.new(@id, flags)
					frame.pack(data, **options)
					
					# This might fail if the data payload was too big:
					consume_remote_window(frame)
					
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
							close!
						end
					else
						raise ProtocolError, "Cannot send data in state: #{@state}"
					end
				end
				
				def close!(state = :closed)
					@state = state
					
					@connection.streams.delete(@id)
				end
				
				def send_reset_stream(error_code = 0)
					if @state != :idle and @state != :closed
						frame = ResetStreamFrame.new(@id)
						frame.pack(error_code)
						
						write_frame(frame)
						
						close!(:reset)
					else
						raise ProtocolError, "Cannot reset stream in state: #{@state}"
					end
				end
				
				private def process_headers(frame)
					# Receiving request headers:
					priority, data = frame.unpack
					
					if priority
						@priority = priority
					end
					
					@connection.decode_headers(data)
				end
				
				def receive_headers(frame)
					if @state == :idle
						if frame.end_stream?
							@state = :half_closed_remote
						else
							@state = :open
						end
						
						@headers = process_headers(frame)
					elsif @state == :reserved_remote
						@state = :half_closed_local
						
						@headers = process_headers(frame)
					elsif @state == :open
						if frame.end_stream?
							@state = :half_closed_remote
						end
						
						@headers = process_headers(frame)
					elsif @state == :half_closed_local
						if frame.end_stream?
							close!
						end
						
						@headers = process_headers(frame)
					elsif @state == :reset
						# ignore...
					else
						raise ProtocolError, "Cannot receive headers in state: #{@state}"
					end
				end
				
				# DATA frames are subject to flow control and can only be sent when a stream is in the "open" or "half-closed (remote)" state.  The entire DATA frame payload is included in flow control, including the Pad Length and Padding fields if present.  If a DATA frame is received whose stream is not in "open" or "half-closed (local)" state, the recipient MUST respond with a stream error of type STREAM_CLOSED.
				def receive_data(frame)
					if @state == :open
						consume_local_window(frame)
						
						if frame.end_stream?
							@state = :half_closed_remote
						end
						
						@data = frame.unpack
					elsif @state == :half_closed_local
						consume_local_window(frame)
						
						if frame.end_stream?
							close!
						end
						
						@data = frame.unpack
					elsif @state == :reset
						# ignore...
					else
						raise ProtocolError, "Cannot receive data in state: #{@state}"
					end
				end
				
				def receive_priority(frame)
					@priority = frame.unpack
				end
				
				def receive_reset_stream(frame)
					if @state != :idle and @state != :closed
						close!
						
						return frame.unpack
					else
						raise ProtocolError, "Cannot reset stream in state: #{@state}"
					end
				end
				
				# A normal request is client request -> server response -> client.
				# A push promise is server request -> client -> server response -> client.
				# The server generates the same set of headers as if the client was sending a request, and sends these to the client. The client can reject the request by resetting the (new) stream. Otherwise, the server will start sending a response as if the client had send the request.
				private def write_push_promise(stream_id, headers, flags = 0, **options)
					data = @connection.encode_headers(headers)
					
					frame = PushPromiseFrame.new(@id, flags)
					frame.pack(stream_id, data, maximum_size: @connection.maximum_frame_size)
					
					write_frame(frame)
					
					return frame
				end
				
				def reserve_local!
					if @state == :idle
						@state = :reserved_local
					else
						raise ProtocolError, "Cannot send push promise in state: #{@state}"
					end
				end
				
				def reserve_remote!
					if @state == :idle
						@state = :reserved_remote
					else
						raise ProtocolError, "Cannot receive push promise in state: #{@state}"
					end
				end
				
				# Server push is semantically equivalent to a server responding to a request; however, in this case, that request is also sent by the server, as a PUSH_PROMISE frame.
				# @param headers [Hash] contains a complete set of request header fields that the server attributes to the request.
				def send_push_promise(headers)
					promised_stream = @connection.create_stream
					promised_stream.reserve_remote!
					
					write_push_promise(promised_stream.id, headers)
					
					return promised_stream
				end
				
				def receive_push_promise(frame)
					promised_stream_id, data = frame.unpack
					headers = @connection.decode_headers(data)
					
					stream = @connection.create_stream(promised_stream_id)
					stream.reserve_local!
					
					return stream, headers
				end
			end
		end
	end
end
