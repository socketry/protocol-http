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

require_relative 'frame'

module HTTP
	module Protocol
		module HTTP2
			module Continued
				def end_headers?
					@flags & END_HEADERS
				end
				
				def read(io)
					super
					
					unless end_headers?
						@continuation = ContinuationFrame.new
						
						@continuation.read(io)
					end
				end
				
				attr_accessor :continuation
				
				def each
					return to_enum unless block_given?
					
					current = self
					
					while current
						yield current
						
						current = current.continuation
					end
				end
			end
			
			class ContinuationFrame < Frame
				prepend Continued
				
				TYPE = 0x9
				
				def data
					@payload
				end
			end
		end
	end
end
