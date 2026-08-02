# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/http/status"

describe Protocol::HTTP::Status do
	it "provides status descriptions" do
		expect(subject.description(100)).to be == "Continue"
		expect(subject.description(200)).to be == "OK"
		expect(subject.description(404)).to be == "Not Found"
		expect(subject.description(500)).to be == "Internal Server Error"
	end
	
	it "uses current descriptions" do
		expect(subject.description(413)).to be == "Content Too Large"
		expect(subject.description(422)).to be == "Unprocessable Content"
	end
	
	it "returns nil for unknown status codes" do
		expect(subject.description(599)).to be_nil
	end
end
