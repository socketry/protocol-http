# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/cookie"

describe Protocol::HTTP::Cookie do
	describe "#initialize" do
		it "accepts valid cookie names" do
			cookie = Protocol::HTTP::Cookie.new("session_id", "123")
			expect(cookie.name).to be == "session_id"
			expect(cookie.value).to be == "123"
		end
		
		it "accepts valid cookie values with allowed characters" do
			# Test cookie-octet range: !#$%&'()*+-./0-9:;<=>?@A-Z[]^_`a-z{|}~
			cookie = Protocol::HTTP::Cookie.new("test", "abc123!#$%&'()*+-./:")
			expect(cookie.value).to be == "abc123!#$%&'()*+-./:"
		end
		
		it "rejects cookie names with invalid characters" do
			expect do
				Protocol::HTTP::Cookie.new("session id", "123")
			end.to raise_exception(ArgumentError, message: be =~ /Invalid cookie name/)
		end
		
		it "rejects cookie names with semicolon" do
			expect do
				Protocol::HTTP::Cookie.new("session;id", "123")
			end.to raise_exception(ArgumentError, message: be =~ /Invalid cookie name/)
		end
		
		it "rejects cookie values with control characters" do
			expect do
				Protocol::HTTP::Cookie.new("session", "123\n456")
			end.to raise_exception(ArgumentError, message: be =~ /Invalid cookie value/)
		end
		
		it "rejects cookie values with semicolon" do
			expect do
				Protocol::HTTP::Cookie.new("session", "123;456")
			end.to raise_exception(ArgumentError, message: be =~ /Invalid cookie value/)
		end
		
		it "rejects cookie values with comma" do
			expect do
				Protocol::HTTP::Cookie.new("session", "123,456")
			end.to raise_exception(ArgumentError, message: be =~ /Invalid cookie value/)
		end
		
		it "rejects cookie values with backslash" do
			expect do
				Protocol::HTTP::Cookie.new("session", "123\\456")
			end.to raise_exception(ArgumentError, message: be =~ /Invalid cookie value/)
		end
		
		it "rejects cookie values with double quote" do
			expect do
				Protocol::HTTP::Cookie.new("session", '"quoted"')
			end.to raise_exception(ArgumentError, message: be =~ /Invalid cookie value/)
		end
		
		it "accepts nil value" do
			cookie = Protocol::HTTP::Cookie.new("session", nil)
			expect(cookie.value).to be_nil
		end
	end
	
	describe "#to_s" do
		it "returns cookie name and value" do
			cookie = Protocol::HTTP::Cookie.new("session", "abc123")
			expect(cookie.to_s).to be == "session=abc123"
		end
		
		it "includes directives" do
			cookie = Protocol::HTTP::Cookie.new("session", "123", {"path" => "/", "secure" => true})
			expect(cookie.to_s).to be == "session=123;path=/;secure"
		end
	end
	
	describe ".parse" do
		it "parses simple cookie" do
			cookie = Protocol::HTTP::Cookie.parse("session=123")
			expect(cookie.name).to be == "session"
			expect(cookie.value).to be == "123"
		end
		
		it "parses cookie with equals in value" do
			cookie = Protocol::HTTP::Cookie.parse("session=123==")
			expect(cookie.name).to be == "session"
			expect(cookie.value).to be == "123=="
		end
		
		it "parses cookie with directives" do
			cookie = Protocol::HTTP::Cookie.parse("session=123; path=/; secure")
			expect(cookie.name).to be == "session"
			expect(cookie.value).to be == "123"
			expect(cookie.directives).to be == {"path" => "/", "secure" => true}
		end
	end
end
