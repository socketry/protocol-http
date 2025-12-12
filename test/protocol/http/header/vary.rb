# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require "protocol/http/header/vary"

describe Protocol::HTTP::Header::Vary do
	let(:header) {subject.parse(description)}
	
	with "#<<" do
		it "can append normalised header names" do
			header << "Accept-Language"
			expect(header).to be(:include?, "accept-language")
		end
	end
	
	with "accept-language" do
		it "should be case insensitive" do
			expect(header).to be(:include?, "accept-language")
		end
		
		it "should not have unspecific keys" do
			expect(header).not.to be(:include?, "user-agent")
		end
	end
	
	with "Accept-Language" do
		it "should be case insensitive" do
			expect(header).to be(:include?, "accept-language")
		end
		
		it "uses normalised lower case keys" do
			expect(header).not.to be(:include?, "Accept-Language")
		end
	end
	
	with ".coerce" do
		it "normalizes array values to lowercase" do
			header = subject.coerce(["Accept-Language", "User-Agent"])
			expect(header).to be(:include?, "accept-language")
			expect(header).to be(:include?, "user-agent")
			expect(header).not.to be(:include?, "Accept-Language")
		end
		
		it "normalizes string values to lowercase" do
			header = subject.coerce("Accept-Language, User-Agent")
			expect(header).to be(:include?, "accept-language")
			expect(header).to be(:include?, "user-agent")
		end
	end
	
	with ".new" do
		it "preserves case when given array" do
			header = subject.new(["Accept-Language", "User-Agent"])
			expect(header).to be(:include?, "Accept-Language")
			expect(header).to be(:include?, "User-Agent")
		end
		
		it "can initialize with string for backward compatibility" do
			header = subject.new("Accept-Language, User-Agent")
			expect(header).to be(:include?, "accept-language")
			expect(header).to be(:include?, "user-agent")
		end
		
		it "raises ArgumentError for invalid value types" do
			expect{subject.new(123)}.to raise_exception(ArgumentError)
		end
	end
end
