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
			# The WINDOW_UPDATE frame is used to implement flow control.
			#
			# +-+-------------------------------------------------------------+
			# |R|              Window Size Increment (31)                     |
			# +-+-------------------------------------------------------------+
			#
			class WindowUpdateFrame < Frame
				TYPE = 0x8
				FORMAT = "N"
				
				# # Maximum window increment value (2^31)
				# MAX_WINDOWINC = 0x7fffffff
				# 
				# attr :increment
				# 
				# def common_header
				# 	if self.incremnet > MAXIMUM_WINDOW_INCREMENT
				# if frame[:type] == :window_update && frame[:increment] > MAX_WINDOWINC
				# 	fail CompressionError, "Window increment (#{frame[:increment]}) is too large"
				# end
				
				def pack(window_size_increment)
					super [window_size_increment].pack(FORMAT)
				end
				
				def unpack
					super.unpack(FORMAT).first
				end
			end
		end
	end
end
