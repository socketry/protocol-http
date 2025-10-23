# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

require "protocol/http/header/cookie"

describe Protocol::HTTP::Header::Cookie do
	let(:header) {subject.new(description)}
	let(:cookies) {header.to_h}
	
	with "session=123; secure" do
		it "can parse cookies" do
			expect(cookies).to have_keys("session")
			
			session = cookies["session"]
			expect(session).to have_attributes(
				name: be == "session",
				value: be == "123",
			)
			expect(session.directives).to have_keys("secure")
		end
	end
	
	with "session=123; path=/; secure" do
		it "can parse cookies" do
			session = cookies["session"]
			expect(session).to have_attributes(
				name: be == "session",
				value: be == "123",
				directives: be == {"path" => "/", "secure" => true},
			)
		end
		
		it "has string representation" do
			session = cookies["session"]
			expect(session.to_s).to be == "session=123;path=/;secure"
		end
	end
	
	with "session=abc123; secure" do
		it "can parse cookies" do
			expect(cookies).to have_keys("session")
			
			session = cookies["session"]
			expect(session).to have_attributes(
				name: be == "session",
				value: be == "abc123",
			)
			expect(session.directives).to have_keys("secure")
		end
		
		it "has string representation" do
			session = cookies["session"]
			expect(session.to_s).to be == "session=abc123;secure"
		end
	end
end
