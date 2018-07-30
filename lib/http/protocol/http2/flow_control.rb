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

require_relative 'window_update_frame'

module HTTP
	module Protocol
		module HTTP2
			module FlowControl
				def available_frame_size
					maximum_frame_size = self.maximum_frame_size
					available_size = @remote_window.available
					
					if available_size < maximum_frame_size
						return available_size
					else
						return maximum_frame_size
					end
				end
				
				# Keep track of the amount of data sent, and fail if is too much.
				def consume_remote_window(frame)
					amount = frame.length
					
					if amount <= @remote_window.available
						@remote_window.consume(amount)
					else
						raise FlowControlError, "Trying to send #{frame.inspect}, exceeded window size: #{@remote_window.available}"
					end
				end
				
				def consume_local_window(frame)
					amount = frame.length
					
					@local_window.consume(amount)
					
					if @local_window.limited?
						self.send_window_update(@local_window.used)
					end
				end
				
				# Notify the remote end that we are prepared to receive more data:
				def send_window_update(window_increment)
					frame = WindowUpdateFrame.new(self.id)
					frame.pack window_increment
					
					write_frame(frame)
					
					@local_window.used -= window_increment
				end
				
				def receive_window_update(frame)
					@remote_window.expand(frame.unpack)
				end
			end
		end
	end
end
