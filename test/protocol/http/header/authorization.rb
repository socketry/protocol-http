# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "protocol/http/header/authorization"
require "protocol/http/headers"

describe Protocol::HTTP::Header::Authorization do
	with "basic username/password" do
		let(:header) {subject.basic("samuel", "password")}
		
		it "should generate correct authorization header" do
			expect(header).to be == "Basic c2FtdWVsOnBhc3N3b3Jk"
		end
		
		with "#credentials" do
			it "can split credentials" do
				expect(header.credentials).to be == ["Basic", "c2FtdWVsOnBhc3N3b3Jk"]
			end
		end
	end
	
	with ".parse" do
		it "parses raw authorization value" do
			result = subject.parse("Bearer token123")
			expect(result).to be_a(subject)
			expect(result).to be == "Bearer token123"
		end
	end
	
	with ".coerce" do
		it "coerces string to Authorization" do
			result = subject.coerce("Bearer xyz")
			expect(result).to be_a(subject)
			expect(result).to be == "Bearer xyz"
		end
	end
end
