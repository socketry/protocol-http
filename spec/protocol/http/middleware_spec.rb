# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require 'protocol/http/middleware'

RSpec.describe Protocol::HTTP::Middleware do
	it "can invoke delegate" do
		request = :request
		
		delegate = instance_double(described_class)
		expect(delegate).to receive(:call) do |request|
			expect(request).to be request
		end
		
		middleware = described_class.new(delegate)
		middleware.call(request)
	end
	
	it "can close delegate" do
		delegate = instance_double(described_class)
		expect(delegate).to receive(:close)
		
		middleware = described_class.new(delegate)
		middleware.close
	end
end
