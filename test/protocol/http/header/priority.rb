# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "protocol/http/header/priority"

describe Protocol::HTTP::Header::Priority do
	let(:header) {subject.new(description)}
	
	with "urgency=low, progressive" do
		it "correctly parses priority header" do
			expect(header).to have_attributes(
				urgency: be == "low",
				progressive?: be == true,
			)
		end
	end
	
	with "urgency=high" do
		it "correctly parses priority header" do
			expect(header).to have_attributes(
				urgency: be == "high",
				progressive?: be == false,
			)
		end
	end
	
	with "progressive" do
		it "correctly parses progressive flag" do
			expect(header).to have_attributes(
				urgency: be_nil,
				progressive?: be == true,
			)
		end
	end
	
	with "urgency=background" do
		it "correctly parses urgency" do
			expect(header).to have_attributes(
				urgency: be == "background",
			)
		end
	end
	
	with "urgency=extreeeeem, progressive" do
		it "gracefully handles non-standard urgency" do
			expect(header).to have_attributes(
				# Non-standard value is preserved
				urgency: be == "extreeeeem",
				progressive?: be == true,
			)
		end
	end
	
	with "urgency=low, urgency=high" do
		it "prioritizes the first urgency directive" do
			expect(header).to have_attributes(
				urgency: be == "low", # First occurrence takes precedence
			)
		end
	end
	
	with "#<<" do
		let(:header) {subject.new}
		
		it "can append values" do
			header << "urgency=low"
			expect(header).to have_attributes(
				urgency: be == "low",
			)
		end
		
		it "can append progressive flag" do
			header << "progressive"
			expect(header).to have_attributes(
				progressive?: be == true,
			)
		end
	end
end
