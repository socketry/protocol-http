# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/header/accept_encoding"
	
describe Protocol::HTTP::Header::AcceptEncoding::Encoding do
	it "should have default quality_factor of 1.0" do
		encoding = subject.new("utf-8", nil)
		expect(encoding.quality_factor).to be == 1.0
	end
end

describe Protocol::HTTP::Header::AcceptEncoding do
	let(:header) {subject.new(description)}
	let(:encodings) {header.encodings.sort}
	
	with "gzip, deflate;q=0.5, identity;q=0.25" do
		it "can parse charsets" do
			expect(header.length).to be == 3
			
			expect(encodings[0].name).to be == "gzip"
			expect(encodings[0].quality_factor).to be == 1.0
			
			expect(encodings[1].name).to be == "deflate"
			expect(encodings[1].quality_factor).to be == 0.5
			
			expect(encodings[2].name).to be == "identity"
			expect(encodings[2].quality_factor).to be == 0.25
		end
	end
	
	with "identity;q=0.25, deflate;q=0.5, gzip" do
		it "should order based on quality factor" do
			expect(encodings.collect(&:name)).to be == %w{gzip deflate identity}
		end
	end
	
	with "br,deflate;q=0.8,identity;q=0.6,gzip" do
		it "should order based on quality factor" do
			expect(encodings.collect(&:name)).to be == %w{br gzip deflate identity}
		end
	end
	
	with "*;q=0" do
		it "should accept wildcard encoding" do
			expect(encodings[0].name).to be == "*"
			expect(encodings[0].quality_factor).to be == 0
		end
	end
	
	with "br, gzip;q=0.5, deflate;q=0.5" do
		it "should preserve relative order" do
			expect(encodings[0].name).to be == "br"
			expect(encodings[1].name).to be == "gzip"
			expect(encodings[2].name).to be == "deflate"
		end
	end
	
	it "should not accept invalid input" do
		bad_values = [
			# Invalid quality factor:
			"br;f=1",
			
			# Invalid parameter:
			"br;gzip",
			
			# Invalid use of separator:
			";",
			
			# Empty (we ignore this one):
			# ","
		]
		
		bad_values.each do |value|
			expect{subject.new(value).encodings}.to raise_exception(subject::ParseError)
		end
	end
end
