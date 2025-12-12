# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/header/accept_language"

describe Protocol::HTTP::Header::AcceptLanguage::Language do
	it "should have default quality_factor of 1.0" do
		language = subject.new("utf-8", nil)
		expect(language.quality_factor).to be == 1.0
	end
end

describe Protocol::HTTP::Header::AcceptLanguage do
	let(:header) {subject.parse(description)}
	let(:languages) {header.languages.sort}
	
	with "da, en-gb;q=0.5, en;q=0.25" do
		it "can parse languages" do
			expect(header.length).to be == 3
			
			expect(languages[0].name).to be == "da"
			expect(languages[0].quality_factor).to be == 1.0
			
			expect(languages[1].name).to be == "en-gb"
			expect(languages[1].quality_factor).to be == 0.5
			
			expect(languages[2].name).to be == "en"
			expect(languages[2].quality_factor).to be == 0.25
		end
	end
	
	with "en-gb;q=0.25, en;q=0.5, en-us" do
		it "should order based on quality factor" do
			expect(languages.collect(&:name)).to be == %w{en-us en en-gb}
		end
	end
	
	with "en-us,en-gb;q=0.8,en;q=0.6,es-419" do
		it "should order based on quality factor" do
			expect(languages.collect(&:name)).to be == %w{en-us es-419 en-gb en}
		end
	end
	
	with "*;q=0" do
		it "should accept wildcard language" do
			expect(languages[0].name).to be == "*"
			expect(languages[0].quality_factor).to be == 0
		end
	end
	
	with "en, de;q=0.5, jp;q=0.5" do
		it "should preserve relative order" do
			expect(languages[0].name).to be == "en"
			expect(languages[1].name).to be == "de"
			expect(languages[2].name).to be == "jp"
		end
	end
	
	with "de, en-US; q=0.7, en ; q=0.3" do
		it "should parse with optional whitespace" do
			expect(languages[0].name).to be == "de"
			expect(languages[1].name).to be == "en-US"
			expect(languages[2].name).to be == "en"
		end
	end
	
	with "en;q=0.123456" do
		it "accepts quality factors with up to 6 decimal places" do
			expect(languages[0].name).to be == "en"
			expect(languages[0].quality_factor).to be == 0.123456
		end
	end
	
	it "should not accept invalid input" do
		bad_values = [
			# Invalid quality factor:
			"en;f=1",
			
			# Invalid parameter:
			"de;fr",
			
			# Invalid use of separator:
			";",
			
			# Empty (we ignore this one):
			# ","
		]
		
		bad_values.each do |value|
			expect{subject.parse(value).languages}.to raise_exception(subject::ParseError)
		end
	end
end
