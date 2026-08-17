# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2026, by Samuel Williams.
# Copyright, 2022, by Herrick Fang.

require "protocol/http/header/cookie"
require "protocol/http/headers"

describe Protocol::HTTP::Header::Cookie do
	let(:header) {subject.parse(description)}
	let(:cookies) {header.to_h}
	
	it "can coerce a single value" do
		header = subject.coerce("session=abc123")
		
		expect(header).to be == ["session=abc123"]
	end
	
	with "session=123; user_id=42" do
		it "can parse cookies" do
			expect(cookies).to have_keys("session", "user_id")
			
			session = cookies["session"]
			expect(session).to have_attributes(
				name: be == "session",
				value: be == "123",
				directives: be == {},
			)
			
			user_id = cookies["user_id"]
			expect(user_id).to have_attributes(
				name: be == "user_id",
				value: be == "42",
				directives: be == {},
			)
		end
	end
	
	with "empty=; token=abc==" do
		it "preserves empty values and equals signs" do
			expect(cookies["empty"].value).to be == ""
			expect(cookies["token"].value).to be == "abc=="
		end
	end
	
	with "first=1 ; second=2;\tthird=3" do
		it "ignores whitespace around separators" do
			expect(cookies.transform_values(&:value)).to be == {
				"first" => "1",
				"second" => "2",
				"third" => "3",
			}
		end
	end
	
	with "session=first; session=second" do
		it "uses the last value for duplicate names" do
			expect(cookies["session"].value).to be == "second"
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
		
		it "joins cookies with semicolons and spaces per RFC 6265" do
			expect(header.to_s).to be == "session=abc123; user_id=42; token=xyz789"
		end
		
		it "parses cookies from multiple header fields" do
			expect(cookies).to have_keys("session", "user_id", "token")
		end
	end
	
	it "parses cookies through protocol headers" do
		headers = Protocol::HTTP::Headers[[
			["cookie", "session=abc123; user_id=42"],
			["cookie", "token=xyz789"],
		]]
		
		header = headers["cookie"]
		
		expect(header).to be_a(subject)
		expect(header.to_h.transform_values(&:value)).to be == {
			"session" => "abc123",
			"user_id" => "42",
			"token" => "xyz789",
		}
	end
end
