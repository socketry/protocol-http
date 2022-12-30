# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'protocol/http/request'

RSpec.describe Protocol::HTTP::Request do
	let(:headers) {Protocol::HTTP::Headers.new}
	let(:body) {nil}
	
	context "simple GET request" do
		subject {described_class.new("http", "localhost", "GET", "/index.html", "HTTP/1.0", headers, body)}
		
		it {is_expected.to have_attributes(
			scheme: "http",
			authority: "localhost",
			method: "GET",
			path: "/index.html",
			version: "HTTP/1.0",
			headers: headers,
			body: body,
			protocol: nil
		)}
		
		it {is_expected.to_not be_head}
		it {is_expected.to_not be_connect}
		it {is_expected.to be_idempotent}
		
		it {is_expected.to have_attributes(
			to_s: "http://localhost: GET /index.html HTTP/1.0"
		)}
	end
end
