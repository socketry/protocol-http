# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'protocol/http/middleware'

describe Protocol::HTTP::Middleware do
	it "can wrap a block" do
		middleware = subject.for do |request|
			Protocol::HTTP::Response[200]
		end
		
		request = Protocol::HTTP::Request['GET', '/']
		
		response = middleware.call(request)
		
		expect(response).to have_attributes(
			status: be == 200,
		)
	end
	
	it "can invoke delegate" do
		request = :request
		
		delegate = subject.new(nil)
		expect(delegate).to(receive(:call) do |request|
			expect(request).to be_equal(request)
		end.and_return(nil))
		
		middleware = subject.new(delegate)
		middleware.call(request)
	end
	
	it "can close delegate" do
		delegate = subject.new(nil)
		expect(delegate).to receive(:close).and_return(nil)
		
		middleware = subject.new(delegate)
		middleware.close
	end
end

describe Protocol::HTTP::Middleware::Okay do
	let(:middleware) {subject}
	
	it "responds with 200" do
		request = Protocol::HTTP::Request['GET', '/']
		
		response = middleware.call(request)
		
		expect(response).to have_attributes(
			status: be == 200,
		)
	end
end

describe Protocol::HTTP::Middleware::NotFound do
	let(:middleware) {subject}
	
	it "responds with 404" do
		request = Protocol::HTTP::Request['GET', '/']
		
		response = middleware.call(request)
		
		expect(response).to have_attributes(
			status: be == 404,
		)
	end
end