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
			Priority = Struct.new(:exclusive, :stream_dependency, :weight) do
				FORMAT = "NC".freeze
				EXCLUSIVE = 1 << 31
				
				def self.unpack(data)
					stream_dependency, weight = data.unpack(FORMAT)
					
					return self.new(stream_dependency & EXCLUSIVE != 0, stream_dependency & ~EXCLUSIVE, weight)
				end
				
				def pack
					if exclusive
						stream_dependency = self.stream_dependency | EXCLUSIVE
					end
					
					return [stream_dependency, self.weight].pack(FORMAT)
				end
			end
			
			# The PRIORITY frame specifies the sender-advised priority of a stream. It can be sent in any stream state, including idle or closed streams.
			#
			# +-+-------------------------------------------------------------+
			# |E|                  Stream Dependency (31)                     |
			# +-+-------------+-----------------------------------------------+
			# |   Weight (8)  |
			# +-+-------------+
			#
			class PriorityFrame < Frame
				TYPE = 0x2
				
				def priority
					Priority.unpack(@payload)
				end
				
				def pack priority
					super priority.pack
				end
				
				def unpack
					Priority.unpack(super)
				end
				
				def apply(connection)
					connection.receive_priority(self)
				end
			end
		end
	end
end
