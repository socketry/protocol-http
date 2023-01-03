# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'protocol/http/response'
require 'protocol/http/request'

describe Protocol::HTTP::Response do
	let(:headers) {Protocol::HTTP::Headers.new}
	let(:body) {nil}
	
	with "GET response" do
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
		
		it "should not be a redirection" do
			expect(response).not.to be(:redirection?)
		end
		
		it "should not be a hijack" do
			expect(response).not.to be(:hijack?)
		end
		
		it "should not be a continue" do
			expect(response).not.to be(:continue?)
		end
		
		it "should be successful" do
			expect(response).to be(:success?)
		end
		
		it "should have a String representation" do
			expect(response.to_s).to be == "200 HTTP/1.0"
		end
		
		it "should have an Array representation" do
			expect(response.to_ary).to be == [200, headers, body]
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
