# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'http/protocol/http1/connection'
require_relative 'connection_context'

RSpec.describe HTTP::Protocol::HTTP1::Connection do
	include_context HTTP::Protocol::HTTP1::Connection
	
	describe '#upgrade' do
		let(:request_upgrade) {"proxy"}
		let(:request_version) {HTTP::Protocol::HTTP1::Connection::HTTP10}
		
		it "should upgrade connection" do
			client.upgrade!(request_upgrade)
			
			client.write_request("testing.com", "GET", "/", request_version, [])
			client.write_upgrade_body
			
			authority, method, path, version, headers, body = server.read_request
			
			expect(version).to be == request_version
			expect(server.upgrade).to be == request_upgrade
			expect(body).to be_nil
		end
	end
end
