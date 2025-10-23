# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/quoted_string"

describe Protocol::HTTP::QuotedString do
	with ".unquote" do
		it "ignores linear whitespace" do
			quoted_string = subject.unquote(%Q{"Hello\r\n  World"})
			
			expect(quoted_string).to be == "Hello World"
		end
	end
	
	with ".quote" do
		it "doesn't quote a string that has no special characters" do
			quoted_string = subject.quote("Hello")
			
			expect(quoted_string).to be == "Hello"
		end
		
		it "quotes a string with a space" do
			quoted_string = subject.quote("Hello World")
			
			expect(quoted_string).to be == %Q{"Hello World"}
		end
		
		it "quotes a string with a double quote" do
			quoted_string = subject.quote(%Q{Hello "World"})
			
			expect(quoted_string).to be == %Q{"Hello \\"World\\""}
		end
		
		it "quotes a string with a backslash" do
			quoted_string = subject.quote(%Q{Hello \\World})
			
			expect(quoted_string).to be == %Q{"Hello \\\\World"}
		end
	end
end
