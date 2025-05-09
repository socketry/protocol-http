# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "protocol/http/header/accept"
	
describe Protocol::HTTP::Header::Accept::MediaRange do
	it "should have default quality_factor of 1.0" do
		media_range = subject.new("text/plain", nil)
		expect(media_range.quality_factor).to be == 1.0
	end
	
	with "#to_s" do
		it "can convert to string" do
			media_range = subject.new("text", "plain", {"q" => "0.5"})
			expect(media_range.to_s).to be == "text/plain;q=0.5"
		end
	end
end

describe Protocol::HTTP::Header::Accept do
	let(:header) {subject.new(description)}
	let(:media_ranges) {header.media_ranges.sort}
	
	with "text/plain, text/html;q=0.5, text/xml;q=0.25" do
		it "can parse media ranges" do
			expect(header.length).to be == 3
			
			expect(media_ranges[0]).to have_attributes(
				type: be == "text",
				subtype: be == "plain",
				quality_factor: be == 1.0
			)
			
			expect(media_ranges[1]).to have_attributes(
				type: be == "text",
				subtype: be == "html",
				quality_factor: be == 0.5
			)
				
			expect(media_ranges[2]).to have_attributes(
				type: be == "text",
				subtype: be == "xml",
				quality_factor: be == 0.25
			)
		end
		
		it "can convert to string" do
			expect(header.to_s).to be == "text/plain,text/html;q=0.5,text/xml;q=0.25"
		end
	end
	
	with "foobar" do
		it "fails to parse" do
			expect{media_ranges}.to raise_exception(Protocol::HTTP::Header::Accept::ParseError)
		end
	end
	
	with "text/html;q=0.25, text/xml;q=0.5, text/plain" do
		it "should order based on quality factor" do
			expect(media_ranges.collect(&:to_s)).to be == %w{text/plain text/xml;q=0.5 text/html;q=0.25}
		end
	end
	
	with "text/html, text/plain;q=0.8, text/xml;q=0.6, application/json" do
		it "should order based on quality factor" do
			expect(media_ranges.collect(&:to_s)).to be == %w{text/html application/json text/plain;q=0.8 text/xml;q=0.6}
		end
	end
	
	with "*/*" do
		it "should accept wildcard media range" do
			expect(media_ranges[0].to_s).to be == "*/*"
		end
	end
	
	with "text/html;schema=\"example.org\";q=0.5" do
		it "should parse parameters" do
			expect(media_ranges[0].parameters).to have_keys(
				"schema" => be == "example.org",
				"q" => be == "0.5",
			)
		end
	end
end
