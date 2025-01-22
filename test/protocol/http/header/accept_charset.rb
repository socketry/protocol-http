# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/header/accept_charset"
	
describe Protocol::HTTP::Header::AcceptCharset::Charset do
	it "should have default quality_factor of 1.0" do
		charset = subject.new("utf-8", nil)
		expect(charset.quality_factor).to be == 1.0
	end
end

describe Protocol::HTTP::Header::AcceptCharset do
	let(:header) {subject.new(description)}
	let(:charsets) {header.charsets.sort}
	
	with "utf-8, iso-8859-1;q=0.5, windows-1252;q=0.25" do
		it "can parse charsets" do
			expect(header.length).to be == 3
			
			expect(charsets[0].name).to be == "utf-8"
			expect(charsets[0].quality_factor).to be == 1.0
			
			expect(charsets[1].name).to be == "iso-8859-1"
			expect(charsets[1].quality_factor).to be == 0.5
			
			expect(charsets[2].name).to be == "windows-1252"
			expect(charsets[2].quality_factor).to be == 0.25
		end
	end
	
	with "windows-1252;q=0.25, iso-8859-1;q=0.5, utf-8" do
		it "should order based on quality factor" do
			expect(charsets.collect(&:name)).to be == %w{utf-8 iso-8859-1 windows-1252}
		end
	end
	
	with "us-ascii,iso-8859-1;q=0.8,windows-1252;q=0.6,utf-8" do
		it "should order based on quality factor" do
			expect(charsets.collect(&:name)).to be == %w{us-ascii utf-8 iso-8859-1 windows-1252}
		end
	end
	
	with "*;q=0" do
		it "should accept wildcard charset" do
			expect(charsets[0].name).to be == "*"
			expect(charsets[0].quality_factor).to be == 0
		end
	end
	
	with "utf-8, iso-8859-1;q=0.5, windows-1252;q=0.5" do
		it "should preserve relative order" do
			expect(charsets[0].name).to be == "utf-8"
			expect(charsets[1].name).to be == "iso-8859-1"
			expect(charsets[2].name).to be == "windows-1252"
		end
	end
	
	it "should not accept invalid input" do
		bad_values = [
			# Invalid quality factor:
			"utf-8;f=1",
			
			# Invalid parameter:
			"us-ascii;utf-8",
			
			# Invalid use of separator:
			";",
			
			# Empty charset (we ignore this one):
			# ","
		]
		
		bad_values.each do |value|
			expect{subject.new(value).charsets}.to raise_exception(subject::ParseError)
		end
	end
end
