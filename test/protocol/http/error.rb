# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

require "protocol/http/error"

describe Protocol::HTTP::DuplicateHeaderError do
	let(:key) {"content-length"}
	let(:existing_value) {"100"}
	let(:new_value) {"200"}
	let(:error) {subject.new(key, existing_value, new_value)}
	
	with "#initialize" do
		it "should set the key and values" do
			expect(error.key).to be == key
			expect(error.existing_value).to be == existing_value
			expect(error.new_value).to be == new_value
		end
		
		it "should have a descriptive message" do
			expect(error.message).to be =~ /Duplicate singleton header key: "content-length"/
		end
	end
	
	with "#detailed_message" do
		it "should include the header key and both values" do
			message = error.detailed_message
			
			expect(message).to be =~ /Duplicate singleton header key: "content-length"/
			expect(message).to be =~ /Existing value: "100"/
			expect(message).to be =~ /New value: "200"/
		end
		
		it "should work with highlight parameter" do
			message = error.detailed_message(highlight: true)
			
			expect(message).to be =~ /Duplicate singleton header key: "content-length"/
			expect(message).to be =~ /Existing value: "100"/
			expect(message).to be =~ /New value: "200"/
		end
	end
end
