# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'protocol/http/header/cache_control'

RSpec.describe Protocol::HTTP::Header::CacheControl do
	subject {described_class.new(description)}
	
	context "accept-language" do
		it {is_expected.to include('accept-language')}
		it {is_expected.to_not include('user-agent')}
	end
	
	context "Accept-Language" do
		it {is_expected.to include('accept-language')}
		it {is_expected.to_not include('Accept-Language')}
	end
end
