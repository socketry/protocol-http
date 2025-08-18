# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require "protocol/http/header/date"

describe Protocol::HTTP::Header::Date do
	let(:header) {subject.new(description)}
	
	with "Wed, 21 Oct 2015 07:28:00 GMT" do
		it "can parse time" do
			time = header.to_time
			expect(time).to be_a(::Time)
			
			expect(time).to have_attributes(
				year: be == 2015,
				month: be == 10,
				mday: be == 21,
				hour: be == 7,
				min: be == 28,
				sec: be == 0
			)
		end
	end
	
	with "#<<" do
		let(:header) {subject.new}
		
		it "can replace values" do
			header << "Wed, 21 Oct 2015 07:28:00 GMT"
			expect(header.to_time).to have_attributes(
				year: be == 2015,
				month: be == 10,
				mday: be == 21
			)
			
			header << "Wed, 22 Oct 2015 07:28:00 GMT"
			expect(header.to_time).to have_attributes(
				year: be == 2015,
				month: be == 10,
				mday: be == 22
			)
		end
	end
	
	describe Protocol::HTTP::Headers do
		let(:headers) {subject[[
				["Date", "Wed, 21 Oct 2015 07:28:00 GMT"],
				["Expires", "Wed, 21 Oct 2015 07:28:00 GMT"],
				["Last-Modified", "Wed, 21 Oct 2015 07:28:00 GMT"],
				["If-Modified-Since", "Wed, 21 Oct 2015 07:28:00 GMT"],
				["If-Unmodified-Since", "Wed, 21 Oct 2015 07:28:00 GMT"]
			]]
		}
		
		it "should parse date headers" do
			# When you convert headers into a hash, the policy is applied (i.e. conversion to Date instances):
			headers.to_h.each do |key, value|
				expect(value).to be_a(Protocol::HTTP::Header::Date)
			end
		end
	end
end
