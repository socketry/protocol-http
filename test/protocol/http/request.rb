# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'protocol/http/request'

describe Protocol::HTTP::Request do
	let(:headers) {Protocol::HTTP::Headers.new}
	let(:body) {nil}
	
	with "simple GET request" do
		let(:request) {subject.new("http", "localhost", "GET", "/index.html", "HTTP/1.0", headers, body)}
		
		it "should have attributes" do
			expect(request).to have_attributes(
				scheme: be == "http",
				authority: be == "localhost",
				method: be == "GET",
				path: be == "/index.html",
				version: be == "HTTP/1.0",
				headers: be == headers,
				body: be == body,
				protocol: be == nil
			)
		end
		
		it "should not be HEAD" do
			expect(request).not.to be(:head?)
		end
		
		it "should not be CONNECT" do
			expect(request).not.to be(:connect?)
		end
		
		it "should be idempotent" do
			expect(request).to be(:idempotent?)
		end
		
		it "should have a string representation" do
			expect(request.to_s).to be == "http://localhost: GET /index.html HTTP/1.0"
		end
		
		it "can apply the request to a connection" do
			connection = proc{|request| request}
			
			expect(connection).to receive(:call).with(request)
			
			request.call(connection)
		end
	end
end
