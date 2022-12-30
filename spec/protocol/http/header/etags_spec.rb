# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'protocol/http/header/etags'

RSpec.describe Protocol::HTTP::Header::ETags do
	subject {described_class.new(description)}
	
	context "*" do
		it {is_expected.to be_wildcard}
		it {is_expected.to be_match('whatever')}
	end
	
	context "abcd" do
		it {is_expected.to_not be_wildcard}
		it {is_expected.to_not be_match('whatever')}
		it {is_expected.to be_match('abcd')}
	end
end
