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

module HTTP
	module Protocol
		# CGI keys (https://tools.ietf.org/html/rfc3875#section-4.1)
		module CGI
			AUTH_TYPE = "AUTH_TYPE".freeze
			CONTENT_LENGTH = "CONTENT_LENGTH".freeze
			CONTENT_TYPE = "CONTENT_TYPE".freeze
			GATEWAY_INTERFACE = "GATEWAY_INTERFACE".freeze
			PATH_INFO = "PATH_INFO".freeze
			PATH_TRANSLATED = "PATH_TRANSLATED".freeze
			QUERY_STRING = "QUERY_STRING".freeze
			REMOTE_ADDR = "REMOTE_ADDR".freeze
			REMOTE_HOST = "REMOTE_HOST".freeze
			REMOTE_IDENT = "REMOTE_IDENT".freeze
			REMOTE_USER = "REMOTE_USER".freeze
			REQUEST_METHOD = "REQUEST_METHOD".freeze
			SCRIPT_NAME = "SCRIPT_NAME".freeze
			SERVER_NAME = "SERVER_NAME".freeze
			SERVER_PORT = "SERVER_PORT".freeze
			SERVER_PROTOCOL = "SERVER_PROTOCOL".freeze
			SERVER_SOFTWARE = "SERVER_SOFTWARE".freeze
		end
	end
end
