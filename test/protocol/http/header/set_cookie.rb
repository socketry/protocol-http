# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/header/set_cookie"

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
		expect(header.to_h).to have_keys("session", "theme")
	end
end
