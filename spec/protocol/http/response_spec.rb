# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'protocol/http/request'

RSpec.describe Protocol::HTTP::Response do
	let(:headers) {Protocol::HTTP::Headers.new}
	let(:body) {nil}
	
	context "GET response" do
		subject {described_class.new("HTTP/1.0", 200, headers, body)}
		
		it {is_expected.to have_attributes(
			version: "HTTP/1.0",
			status: 200,
			headers: headers,
			body: body,
			protocol: nil
		)}
		
		it {is_expected.to_not be_hijack}
		it {is_expected.to_not be_continue}
		it {is_expected.to be_success}
		
		it {is_expected.to have_attributes(
			to_ary: [200, headers, body]
		)}
		
		it {is_expected.to have_attributes(
			to_s: "200 HTTP/1.0"
		)}
	end
	
	context "unmodified cached response" do
		subject {described_class.new("HTTP/1.1", 304, headers, body)}
		
		it {is_expected.to_not be_success}
		it {is_expected.to be_redirection}
		it {is_expected.to be_not_modified}
	end
end
