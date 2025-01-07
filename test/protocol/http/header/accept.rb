# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2016, by Matthew Kerwin.
# Copyright, 2017-2024, by Samuel Williams.

require 'protocol/http/header/accept'
	
describe Protocol::HTTP::Header::Accept::MediaRange do
	it "should have default quality_factor of 1.0" do
		language = subject.new('text/plain', nil)
		expect(language.quality_factor).to be == 1.0
	end
end

describe Protocol::HTTP::Header::Accept do
	let(:header) {subject.new(description)}
	let(:media_ranges) {header.media_ranges.sort}
	
	with "text/plain, text/html;q=0.5, text/xml;q=0.25" do
		it "can parse media ranges" do
			expect(header.length).to be == 3
			
			expect(media_ranges[0].mime_type).to be == "text/plain"
			expect(media_ranges[0].quality_factor).to be == 1.0
			
			expect(media_ranges[1].mime_type).to be == "text/html"
			expect(media_ranges[1].quality_factor).to be == 0.5
			
			expect(media_ranges[2].mime_type).to be == "text/xml"
			expect(media_ranges[2].quality_factor).to be == 0.25
		end
	end
	
	with "text/html;q=0.25, text/xml;q=0.5, text/plain" do
		it "should order based on quality factor" do
			expect(media_ranges.collect(&:mime_type)).to be == %w{text/plain text/xml text/html}
		end
	end
	
	with "text/html, text/plain;q=0.8, text/xml;q=0.6, application/json" do
		it "should order based on quality factor" do
			expect(media_ranges.collect(&:mime_type)).to be == %w{text/html application/json text/plain text/xml}
		end
	end
	
	with "*/*;q=0" do
		it "should accept wildcard media range" do
			expect(media_ranges[0].mime_type).to be == "*/*"
			expect(media_ranges[0].quality_factor).to be == 0
		end
	end
	
	
end
