# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.
# Copyright, 2023, by Thomas Morgan.

require 'protocol/http/header/cache_control'

describe Protocol::HTTP::Header::CacheControl do
	let(:header) {subject.new(description)}
	
	with "max-age=60, s-maxage=30, public" do
		it "correctly parses cache header" do
			expect(header).to have_attributes(
				public?: be == true,
				private?: be == false,
				max_age: be == 60,
				s_maxage: be == 30,
			)
		end
	end
	
	with "max-age=-10, s-maxage=0x22" do
		it "gracefully handles invalid values" do
			expect(header).to have_attributes(
				max_age: be == nil,
				s_maxage: be == nil,
			)
		end
	end
	
	with "no-cache, no-store" do
		it "correctly parses cache header" do
			expect(header).to have_attributes(
				no_cache?: be == true,
				no_store?: be == true,
			)
		end
	end
	
	with "static" do
		it "correctly parses cache header" do
			expect(header).to have_attributes(
				static?: be == true,
			)
		end
	end
	
	with "dynamic" do
		it "correctly parses cache header" do
			expect(header).to have_attributes(
				dynamic?: be == true,
			)
		end
	end
	
	with "streaming" do
		it "correctly parses cache header" do
			expect(header).to have_attributes(
				streaming?: be == true,
			)
		end
	end
	
	with "must-revalidate" do
		it "correctly parses cache header" do
			expect(header).to have_attributes(
				must_revalidate?: be == true,
			)
		end
	end
	
	with "proxy-revalidate" do
		it "correctly parses cache header" do
			expect(header).to have_attributes(
				proxy_revalidate?: be == true,
			)
		end
	end
	
	with "#<<" do
		let(:header) {subject.new}
		
		it "can append values" do
			header << "max-age=60"
			expect(header).to have_attributes(
				max_age: be == 60,
			)
		end
	end
end
