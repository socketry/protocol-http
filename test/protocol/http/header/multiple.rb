# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

require "protocol/http/header/multiple"

describe Protocol::HTTP::Header::Multiple do
	let(:header) {subject.parse(description)}
	
	with "first-value" do
		it "can add several values" do
			header << "second-value"
			header << "third-value"
			
			expect(header).to be == ["first-value", "second-value", "third-value"]
			expect(header).to have_attributes(
				to_s: be == "first-value\nsecond-value\nthird-value"
			)
		end
	end
	
	with ".trailer?" do
		it "is not allowed in trailers by default" do
			expect(subject).not.to be(:trailer?)
		end
	end
end
