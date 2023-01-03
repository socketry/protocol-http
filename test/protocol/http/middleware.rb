# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'protocol/http/middleware'

describe Protocol::HTTP::Middleware do
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
