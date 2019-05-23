# frozen_string_literal: true
#
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

module Protocol
	module HTTP
		# HTTP method verbs
		class Methods
			GET = 'GET'
			POST = 'POST'
			PUT = 'PUT'
			PATCH = 'PATCH'
			DELETE = 'DELETE'
			HEAD = 'HEAD'
			OPTIONS = 'OPTIONS'
			LINK = 'LINK'
			UNLINK = 'UNLINK'
			TRACE = 'TRACE'
			CONNECT = 'CONNECT'
			
			def self.each
				constants.each do |name|
					yield name, const_get(name)
				end
			end
			
			# Use Methods.constants to get all constants.
			self.each do |name, verb|
				define_method(verb.downcase) do |location, headers = [], body = nil|
					self.call(
						Request[verb, location.to_str, Headers[headers], body]
					)
				end
			end
		end
	end
end
