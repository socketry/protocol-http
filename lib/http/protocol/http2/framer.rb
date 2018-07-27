# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# Copyrigh, 2013, by Ilya Grigorik.
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

require_relative '../error'

require_relative 'data_frame'
require_relative 'headers_frame'
require_relative 'priority_frame'
require_relative 'reset_stream_frame'
require_relative 'settings_frame'
require_relative 'push_promise_frame'
require_relative 'ping_frame'
require_relative 'goaway_frame'
require_relative 'window_update_frame'
require_relative 'continuation_frame'
require_relative 'alternative_service_frame'

module HTTP
	module Protocol
		module HTTP2
			# HTTP/2 frame type mapping as defined by the spec
			FRAMES = [
				DataFrame,
				HeadersFrame,
				PriorityFrame,
				ResetStreamFrame,
				SettingsFrame,
				PushPromiseFrame,
				PingFrame,
				GoawayFrame,
				WindowUpdateFrame,
				ContinuationFrame,
			].freeze
			
			class Framer
				def initialize(io, frames = FRAMES)
					@io = io
					@frames = frames
				end
				
				def read_frame
					length, type, flags, stream_id = read_header
					
					payload = @io.read(length) if length > 0
					
					klass = @frames[type] || Frame
					
					return klass.new(length, type, flags, stream_id, payload)
				end
				
				private
				
				def read_header
					return Frame.parse_header(@io.read(9))
				end
			end
		end
	end
end
