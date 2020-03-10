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

require 'protocol/http/accept_encoding'
require 'protocol/http/content_encoding'

RSpec.describe Protocol::HTTP::ContentEncoding do
	context 'with complete text/plain response' do
		subject do
			described_class.new(Protocol::HTTP::Middleware::HelloWorld)
		end
		
		it "can request resource with compression" do
			compressor = Protocol::HTTP::AcceptEncoding.new(subject)
			
			response = compressor.get("/index", {'accept-encoding' => 'gzip'})
			expect(response).to be_success
			
			expect(response.headers['vary']).to include('accept-encoding')
			
			expect(response.body).to be_kind_of Protocol::HTTP::Body::Inflate
			expect(response.read).to be == "Hello World!"
		end
		
		it "can request resource without compression" do
			response = subject.get("/index")
			
			expect(response).to be_success
			expect(response.headers).to_not include('content-encoding')
			expect(response.headers['vary']).to include('accept-encoding')
			
			expect(response.read).to be == "Hello World!"
		end
	end
	
	context 'with partial response' do
		let(:app) do
			app = ->(request){
				Protocol::HTTP::Response[206, Protocol::HTTP::Headers['content-type' => 'text/plain'], ["Hello World!"]]
			}
		end
			
		subject do
			described_class.new(app)
		end
		
		it "can request resource with compression" do
			response = subject.get("/index", {'accept-encoding' => 'gzip'})
			expect(response).to be_success
			
			expect(response.headers).to_not include('content-encoding')
			expect(response.read).to be == "Hello World!"
		end
	end
	
	context 'with existing content encoding' do
		let(:app) do
			app = ->(request){
				Protocol::HTTP::Response[200, Protocol::HTTP::Headers['content-type' => 'text/plain', 'content-encoding' => 'identity'], ["Hello World!"]]
			}
		end
			
		subject do
			described_class.new(app)
		end
		
		it "does not compress response" do
			response = subject.get("/index", {'accept-encoding' => 'gzip'})
			
			expect(response).to be_success
			expect(response.headers).to include('content-encoding')
			expect(response.headers['content-encoding']).to be == ['identity']
			
			expect(response.read).to be == "Hello World!"
		end
	end
end
