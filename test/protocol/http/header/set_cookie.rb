# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/header/set_cookie"
require "protocol/http/headers"

describe Protocol::HTTP::Header::SetCookie do
	let(:header) do
		subject.coerce([
			"session=abc123; Path=/",
			"theme=dark; HttpOnly",
		])
	end
	
	it "represents values which must be emitted as separate fields" do
		expect(header).to be_a(Protocol::HTTP::Header::Multiple)
		expect(header).to be == ["session=abc123; Path=/", "theme=dark; HttpOnly"]
	end
	
	it "can extract parsed cookies" do
		cookies = header.to_h
		
		expect(cookies).to have_keys("session", "theme")
		expect(cookies["session"]).to have_attributes(
			value: be == "abc123",
			directives: be == {"Path" => "/"},
		)
		expect(cookies["theme"]).to have_attributes(
			value: be == "dark",
			directives: be == {"HttpOnly" => true},
		)
	end
	
	it "preserves cookie attributes" do
		header = subject.parse("session=abc123; Path=/; HttpOnly; SameSite=Lax; Max-Age=3600; Expires=Wed, 21 Oct 2015 07:28:00 GMT")
		cookie = header.to_h["session"]
		
		expect(cookie.directives).to be == {
			"Path" => "/",
			"HttpOnly" => true,
			"SameSite" => "Lax",
			"Max-Age" => "3600",
			"Expires" => "Wed, 21 Oct 2015 07:28:00 GMT",
		}
	end
	
	it "preserves separate fields through protocol headers" do
		headers = Protocol::HTTP::Headers[[
			["set-cookie", "session=abc123; Path=/; HttpOnly"],
			["set-cookie", "theme=dark; SameSite=Lax"],
		]]
		
		header = headers["set-cookie"]
		cookies = header.to_h
		
		expect(header).to be_a(subject)
		expect(header).to be == [
			"session=abc123; Path=/; HttpOnly",
			"theme=dark; SameSite=Lax",
		]
		expect(cookies["session"].directives).to be == {"Path" => "/", "HttpOnly" => true}
		expect(cookies["theme"].directives).to be == {"SameSite" => "Lax"}
	end
end
