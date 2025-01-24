# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require "protocol/http/request"

require "json"

describe Protocol::HTTP::Request do
	let(:headers) {Protocol::HTTP::Headers.new}
	let(:body) {nil}
	
	with ".[]" do
		let(:body) {Protocol::HTTP::Body::Buffered.wrap("Hello, World!")}
		let(:headers) {Protocol::HTTP::Headers[{"accept" => "text/html"}]}
		
		it "creates a new request" do
			request = subject["GET", "/index.html", headers]
			
			expect(request).to have_attributes(
				scheme: be_nil,
				authority: be_nil,
				method: be == "GET",
				path: be == "/index.html",
				version: be_nil,
				headers: be == headers,
				body: be_nil,
				protocol: be_nil
			)
		end
		
		it "creates a new request with keyword arguments" do
			request = subject["GET", "/index.html", scheme: "http", authority: "localhost", headers: headers, body: body]
			
			expect(request).to have_attributes(
				scheme: be == "http",
				authority: be == "localhost",
				method: be == "GET",
				path: be == "/index.html",
				version: be_nil,
				headers: be == headers,
				body: be == body,
				protocol: be_nil
			)
		end
		
		it "converts header hash to headers instance" do
			request = subject["GET", "/index.html", {"accept" => "text/html"}]
			
			expect(request).to have_attributes(
				headers: be == headers,
			)
		end
		
		it "converts array body to buffered body" do
			request = subject["GET", "/index.html", headers: headers, body: ["Hello, World!"]]
			
			expect(request).to have_attributes(
				body: be_a(Protocol::HTTP::Body::Buffered)
			)
		end
	end
	
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
				protocol: be_nil,
				peer: be_nil,
			)
		end
		
		with "#as_json" do
			it "generates a JSON representation" do
				expect(request.as_json).to be == {
					scheme: "http",
					authority: "localhost",
					method: "GET",
					path: "/index.html",
					version: "HTTP/1.0",
					headers: headers.as_json,
					body: nil,
					protocol: nil
				}
			end
			
			it "generates a JSON string" do
				expect(JSON.dump(request)).to be == request.to_json
			end
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
	
	with "interim response" do
		let(:request) {subject.new("http", "localhost", "GET", "/index.html", "HTTP/1.0", headers, body)}
		
		it "should call block" do
			request.on_interim_response do |status, headers|
				expect(status).to be == 100
				expect(headers).to be == {}
			end
			
			request.send_interim_response(100, {})
		end
		
		it "calls multiple blocks" do
			sequence = []
			
			request.on_interim_response do |status, headers|
				sequence << 1
				
				expect(status).to be == 100
				expect(headers).to be == {}
			end
			
			request.on_interim_response do |status, headers|
				sequence << 2
				
				expect(status).to be == 100
				expect(headers).to be == {}
			end
			
			request.send_interim_response(100, {})
			
			expect(sequence).to be == [2, 1]
		end
	end
end
