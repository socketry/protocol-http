# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2022, by Samuel Williams.

require 'protocol/http'

RSpec.describe Protocol::HTTP do
	it "has a version number" do
		expect(Protocol::HTTP::VERSION).not_to be nil
	end
end
