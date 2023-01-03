# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'protocol/http/middleware'
require 'protocol/http/middleware/builder'

describe Protocol::HTTP::Middleware::Builder do
	it "can make an app" do
		app = Protocol::HTTP::Middleware.build do
			run Protocol::HTTP::Middleware::HelloWorld
		end
		
		expect(app).to be_equal(Protocol::HTTP::Middleware::HelloWorld)
	end
	
	it "defaults to not found" do
		app = Protocol::HTTP::Middleware.build do
		end
		
		expect(app).to be_equal(Protocol::HTTP::Middleware::NotFound)
	end
	
	it "can instantiate middleware" do
		app = Protocol::HTTP::Middleware.build do
			use Protocol::HTTP::Middleware
		end
		
		expect(app).to be_a(Protocol::HTTP::Middleware)
	end
end
