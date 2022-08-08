# frozen_string_literal: true

# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require_relative 'body/buffered'
require_relative 'body/reader'

module Protocol
	module HTTP
		class Request
			prepend Body::Reader
			
			def initialize(scheme = nil, authority = nil, method = nil, path = nil, version = nil, headers = Headers.new, body = nil, protocol = nil)
				@scheme = scheme
				@authority = authority
				@method = method
				@path = path
				@version = version
				@headers = headers
				@body = body
				@protocol = protocol
			end
			
			# The request scheme, usually one of "http" or "https".
			attr_accessor :scheme

			# The request authority, usually a hostname and port number.
			attr_accessor :authority

			# The request method, usually one of "GET", "HEAD", "POST", "PUT", "DELETE", "CONNECT" or "OPTIONS".
			attr_accessor :method

			# The request path, usually a path and query string.
			attr_accessor :path

			# The request version, usually "http/1.0", "http/1.1", "h2", or "h3".
			attr_accessor :version

			# The request headers, contains metadata associated with the request such as the user agent, accept (content type), accept-language, etc.
			attr_accessor :headers

			# The request body, an instance of Protocol::HTTP::Body::Readable or similar.
			attr_accessor :body

			# The request protocol, usually empty, but occasionally "websocket" or "webtransport", can be either single value `String` or multi-value `Array` of `String` instances. In HTTP/1, it is used to request a connection upgrade, and in HTTP/2 it is used to indicate a specfic protocol for the stream.
			attr_accessor :protocol
			
			# Send the request to the given connection.
			def call(connection)
				connection.call(self)
			end
			
			def head?
				@method == Methods::HEAD
			end
			
			def connect?
				@method == Methods::CONNECT
			end
			
			def self.[](method, path, headers, body)
				body = Body::Buffered.wrap(body)
				headers = ::Protocol::HTTP::Headers[headers]
				
				self.new(nil, nil, method, path, nil, headers, body)
			end
			
			def idempotent?
				@method != Methods::POST && (@body.nil? || @body.empty?)
			end
			
			def to_s
				"#{@scheme}://#{@authority}: #{@method} #{@path} #{@version}"
			end
		end
	end
end
