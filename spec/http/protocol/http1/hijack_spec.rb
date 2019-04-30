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
	
	describe '#hijack' do
		let(:response_version) {HTTP::Protocol::HTTP1::Connection::HTTP10}
		let(:response_headers) {Hash.new('upgrade' => 'websocket')}
		let(:body) {double}
		let(:text) {"Hello World!"}
		
		it "should use non-chunked output" do
			server_wrapper = server.hijack
			expect(server.persistent).to be false
			
			expect(body).to receive(:empty?).and_return(false)
			expect(body).to receive(:length).and_return(nil)
			expect(body).to receive(:each).and_return(nil)
			
			expect(server).to receive(:write_body_and_close).and_call_original
			server.write_response(response_version, 101, response_headers, body)
			
			version, status, reason, headers, body = client.read_response("GET")
			
			expect(version).to be == response_version
			expect(status).to be == 101
			expect(headers).to be == response_headers
			expect(body).to be_nil # due to 101 status
			
			client_wrapper = client.hijack
			
			client_wrapper.write(text)
			client_wrapper.close
			
			expect(server_wrapper.read).to be == text
		end
	end
end
