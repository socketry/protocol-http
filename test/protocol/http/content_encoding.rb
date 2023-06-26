# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'protocol/http/accept_encoding'
require 'protocol/http/content_encoding'

describe Protocol::HTTP::ContentEncoding do
	with 'complete text/plain response' do
		let(:middleware) {subject.new(Protocol::HTTP::Middleware::HelloWorld)}
		let(:accept_encoding) {Protocol::HTTP::AcceptEncoding.new(middleware)}
		
		it "can request resource without compression" do
			response = middleware.get("/index")
			
			expect(response).to be(:success?)
			expect(response.headers).not.to have_keys('content-encoding')
			expect(response.headers['vary']).to be(:include?, 'accept-encoding')
			
			expect(response.read).to be == "Hello World!"
		end
		
		it "can request a resource with the identity encoding" do
			response = accept_encoding.get("/index", {'accept-encoding' => 'identity'})
			
			expect(response).to be(:success?)
			expect(response.headers).not.to have_keys('content-encoding')
			expect(response.headers['vary']).to be(:include?, 'accept-encoding')
			
			expect(response.read).to be == "Hello World!"
		end
		
		it "can request resource with compression" do
			response = accept_encoding.get("/index", {'accept-encoding' => 'gzip'})
			expect(response).to be(:success?)
			
			expect(response.headers['vary']).to be(:include?, 'accept-encoding')
			
			expect(response.body).to be_a(Protocol::HTTP::Body::Inflate)
			expect(response.read).to be == "Hello World!"
		end
	end
	
	with 'partial response' do
		let(:app) do
			app = ->(request){
				Protocol::HTTP::Response[206, Protocol::HTTP::Headers['content-type' => 'text/plain'], ["Hello World!"]]
			}
		end
			
		let(:client) {subject.new(app)}
		
		it "can request resource with compression" do
			response = client.get("/index", {'accept-encoding' => 'gzip'})
			expect(response).to be(:success?)
			
			expect(response.headers).not.to have_keys('content-encoding')
			expect(response.read).to be == "Hello World!"
		end
	end
	
	with 'existing content encoding' do
		let(:app) do
			app = ->(request){
				Protocol::HTTP::Response[200, Protocol::HTTP::Headers['content-type' => 'text/plain', 'content-encoding' => 'identity'], ["Hello World!"]]
			}
		end
			
		let(:client) {subject.new(app)}
		
		it "does not compress response" do
			response = client.get("/index", {'accept-encoding' => 'gzip'})
			
			expect(response).to be(:success?)
			expect(response.headers).to have_keys('content-encoding')
			expect(response.headers['content-encoding']).to be == ['identity']
			
			expect(response.read).to be == "Hello World!"
		end
	end
end
