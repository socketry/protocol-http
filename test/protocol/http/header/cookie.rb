# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

require "protocol/http/header/cookie"

describe Protocol::HTTP::Header::Cookie do
	let(:header) {subject.parse(description)}
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
	end
	
	with "multiple cookies" do
		let(:header) do
			cookie = subject.new
			cookie << "session=abc123"
			cookie << "user_id=42"
			cookie << "token=xyz789"
			cookie
		end
		
		it "joins cookies with semicolons without spaces" do
			expect(header.to_s).to be == "session=abc123;user_id=42;token=xyz789"
		end
	end
end
