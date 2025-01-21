# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

require "protocol/http"

describe Protocol::HTTP do
	it "has a version number" do
		expect(Protocol::HTTP::VERSION).to be =~ /\d+\.\d+\.\d+/
	end
end
