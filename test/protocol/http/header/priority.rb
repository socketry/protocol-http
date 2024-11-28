# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "protocol/http/header/priority"

describe Protocol::HTTP::Header::Priority do
	let(:header) { subject.new(description) }
	
	with "u=1, i" do
		it "correctly parses priority header" do
			expect(header).to have_attributes(
				urgency: be == 1,
				incremental?: be == true,
			)
		end
	end
	
	with "u=0" do
		it "correctly parses priority header" do
			expect(header).to have_attributes(
				urgency: be == 0,
				incremental?: be == false,
			)
		end
	end
	
	with "i" do
		it "correctly parses incremental flag" do
			expect(header).to have_attributes(
				# Default urgency level is used:
				urgency: be == 3,
				incremental?: be == true,
			)
		end
	end
	
	with "u=6" do
		it "correctly parses urgency level" do
			expect(header).to have_attributes(
				urgency: be == 6,
			)
		end
	end
	
	with "u=9, i" do
		it "gracefully handles non-standard urgency levels" do
			expect(header).to have_attributes(
				# Non-standard value is preserved
				urgency: be == 9,
				incremental?: be == true,
			)
		end
	end
	
	with "u=2, u=5" do
		it "prioritizes the first urgency directive" do
			expect(header).to have_attributes(
				# First occurrence takes precedence
				urgency: be == 2,
			)
		end
	end
	
	with "#<<" do
		let(:header) { subject.new }
		
		it "can append values" do
			header << "u=4"
			expect(header).to have_attributes(
				urgency: be == 4,
			)
		end
		
		it "can append incremental flag" do
			header << "i"
			expect(header).to have_attributes(
				incremental?: be == true,
			)
		end
	end
end
