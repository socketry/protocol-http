# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "protocol/http/methods"
require "protocol/http/request"

ValidMethod = Sus::Shared("valid method") do |name|
	it "defines #{name} method" do
		expect(Protocol::HTTP::Methods.constants).to be(:include?, name.to_sym)
	end
	
	it "has correct value" do
		expect(Protocol::HTTP::Methods.const_get(name)).to be == name.to_s
	end
	
	it "is a valid method" do
		expect(Protocol::HTTP::Methods).to be(:valid?, name)
	end
end

describe Protocol::HTTP::Methods do
	it "defines several methods" do
		expect(subject.constants).not.to be(:empty?)
	end
	
	it_behaves_like ValidMethod, "GET"
	it_behaves_like ValidMethod, "POST"
	it_behaves_like ValidMethod, "PUT"
	it_behaves_like ValidMethod, "PATCH"
	it_behaves_like ValidMethod, "DELETE"
	it_behaves_like ValidMethod, "HEAD"
	it_behaves_like ValidMethod, "OPTIONS"
	it_behaves_like ValidMethod, "TRACE"
	it_behaves_like ValidMethod, "CONNECT"
	it_behaves_like ValidMethod, "QUERY"
	
	it "defines exactly 10 methods" do
		expect(subject.constants.length).to be == 10
	end
	
	it "defines QUERY helper method" do
		middleware = Class.new(subject) do
			attr :request
			
			def call(request)
				@request = request
			end
		end.new
		
		middleware.query("/search", body: "term=ruby")
		
		expect(middleware.request).to have_attributes(
			method: be == "QUERY",
			path: be == "/search",
		)
	end
	
	with ".valid?" do
		with "FOOBAR" do
			it "is not a valid method" do
				expect(subject).not.to be(:valid?, description)
			end
		end
		
		with "GETEMALL" do
			it "is not a valid method" do
				expect(subject).not.to be(:valid?, description)
			end
		end
		
		with "Accept:" do
			it "is not a valid method" do
				expect(subject).not.to be(:valid?, description)
			end
		end
	end
end
