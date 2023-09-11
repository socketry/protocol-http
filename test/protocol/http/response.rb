# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'protocol/http/response'
require 'protocol/http/request'

describe Protocol::HTTP::Response do
	let(:headers) {Protocol::HTTP::Headers.new}
	let(:body) {nil}
	
	InformationalResponse = Sus::Shared("informational response") do
		it "should be informational" do
			expect(response).to be(:informational?)
		end
		
		it "should not be a failure" do
			expect(response).not.to be(:failure?)
		end
	end
	
	SuccessfulResponse = Sus::Shared("successful response") do
		it "should be successful" do
			expect(response).to be(:success?)
		end
		
		it "should be final" do
			expect(response).to be(:final?)
		end
		
		it "should not be informational" do
			expect(response).not.to be(:informational?)
		end
		
		it "should not be a failure" do
			expect(response).not.to be(:failure?)
		end
	end
	
	RedirectionResponse = Sus::Shared("redirection response") do
		it "should be final" do
			expect(response).to be(:final?)
		end
		
		it "should be a redirection" do
			expect(response).to be(:redirection?)
		end
		
		it "should not be informational" do
			expect(response).not.to be(:informational?)
		end
		
		it "should not be a failure" do
			expect(response).not.to be(:failure?)
		end
	end
	
	FailureResponse = Sus::Shared("failure response") do
		it "should not be successful" do
			expect(response).not.to be(:success?)
		end
		
		it "should be final" do
			expect(response).to be(:final?)
		end
		
		it "should not be informational" do
			expect(response).not.to be(:informational?)
		end
		
		it "should be a failure" do
			expect(response).to be(:failure?)
		end
	end
	
	RedirectUsingOriginalMethod = Sus::Shared("redirect using original method") do
		it "should preserve the method when following the redirect" do
			expect(response).to be(:preserve_method?)
		end
	end
	
	RedirectUsingGetAllowed = Sus::Shared("redirect using get allowed") do
		it "should not preserve the method when following the redirect" do
			expect(response).not.to be(:preserve_method?)
		end
	end
	
	with "100 Continue" do
		let(:response) {subject.new("HTTP/1.1", 100, headers)}
		
		it "should have attributes" do
			expect(response).to have_attributes(
				version: be == "HTTP/1.1",
				status: be == 100,
				headers: be == headers,
				body: be == nil,
				protocol: be == nil
			)
		end
		
		it_behaves_like InformationalResponse
		
		it "should be a continue" do
			expect(response).to be(:continue?)
		end
		
		it "should have a String representation" do
			expect(response.to_s).to be == "100 HTTP/1.1"
		end
		
		it "should have an Array representation" do
			expect(response.to_ary).to be == [100, headers, nil]
		end
	end
	
	with "301 Moved Permanently" do
		let(:response) {subject.new("HTTP/1.1", 301, headers, body)}
		
		it_behaves_like RedirectionResponse
		it_behaves_like RedirectUsingGetAllowed
	end
	
	with "302 Moved Permanently" do
		let(:response) {subject.new("HTTP/1.1", 301, headers, body)}
		
		it_behaves_like RedirectionResponse
		it_behaves_like RedirectUsingGetAllowed
	end
	
	with "307 Temporary Redirect" do
		let(:response) {subject.new("HTTP/1.1", 307, headers, body)}
		
		it_behaves_like RedirectionResponse
		it_behaves_like RedirectUsingOriginalMethod
	end
	
	with "308 Permanent Redirect" do
		let(:response) {subject.new("HTTP/1.1", 308, headers, body)}
		
		it_behaves_like RedirectionResponse
		it_behaves_like RedirectUsingOriginalMethod
	end
	
	with "200 OK" do
		let(:response) {subject.new("HTTP/1.0", 200, headers, body)}
		
		it "should have attributes" do
			expect(response).to have_attributes(
				version: be == "HTTP/1.0",
				status: be == 200,
				headers: be == headers,
				body: be == body,
				protocol: be == nil
			)
		end
		
		it_behaves_like SuccessfulResponse
		
		it "should be ok" do
			expect(response).to be(:ok?)
		end
		
		it "should not be a redirection" do
			expect(response).not.to be(:redirection?)
		end
		
		it "should not be a hijack" do
			expect(response).not.to be(:hijack?)
		end
		
		it "should not be a continue" do
			expect(response).not.to be(:continue?)
		end
		
		it "should have a String representation" do
			expect(response.to_s).to be == "200 HTTP/1.0"
		end
		
		it "should have an Array representation" do
			expect(response.to_ary).to be == [200, headers, body]
		end
	end
	
	with "400 Bad Request" do
		let(:response) {subject.new("HTTP/1.1", 400, headers, body)}
		
		it_behaves_like FailureResponse
		
		it "should be a bad request" do
			expect(response).to be(:bad_request?)
		end
	end
	
	with "500 Internal Server Error" do
		let(:response) {subject.new("HTTP/1.1", 500, headers, body)}
		
		it_behaves_like FailureResponse
		
		it "should be an internal server error" do
			expect(response).to be(:internal_server_error?)
		end
	end
	
	with ".for_exception" do
		let(:exception) {StandardError.new("Something went wrong")}
		let(:response) {subject.for_exception(exception)}
		
		it "should have a 500 status" do
			expect(response.status).to be == 500
			
			expect(response.body.read).to be =~ /Something went wrong/
		end
	end
	
	with "unmodified cached response" do
		let(:response) {subject.new("HTTP/1.1", 304, headers, body)}
		
		it "should have attributes" do
			expect(response).to have_attributes(
				version: be == "HTTP/1.1",
				status: be == 304,
				headers: be == headers,
				body: be == body,
				protocol: be == nil
			)
		end
		
		it "should not be successful" do
			expect(response).not.to be(:success?)
		end
		
		it "should be a redirection" do
			expect(response).to be(:redirection?)
		end
		
		it "should be not modified" do
			expect(response).to be(:not_modified?)
		end
	end
end
