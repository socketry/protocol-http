# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'protocol/http/header/cache_control'

RSpec.describe Protocol::HTTP::Header::CacheControl do
	subject {described_class.new(description)}
	
	context "max-age=60, public" do
		it {is_expected.to have_attributes(public?: true)}
		it {is_expected.to have_attributes(private?: false)}
		it {is_expected.to have_attributes(max_age: 60)}
	end
	
	context "no-cache, no-store" do
		it {is_expected.to have_attributes(no_cache?: true)}
		it {is_expected.to have_attributes(no_store?: true)}
	end
end
