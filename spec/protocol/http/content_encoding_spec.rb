# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

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
