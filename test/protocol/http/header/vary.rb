# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'protocol/http/header/vary'

describe Protocol::HTTP::Header::Vary do
	let(:header) {subject.new(description)}
	
	with '#<<' do
		it "can append normalised header names" do
			header << 'Accept-Language'
			expect(header).to be(:include?, 'accept-language')
		end
	end
	
	with "accept-language" do
		it "should be case insensitive" do
			expect(header).to be(:include?, 'accept-language')
		end
		
		it "should not have unspecific keys" do
			expect(header).not.to be(:include?, 'user-agent')
		end
	end
	
	with "Accept-Language" do
		it "should be case insensitive" do
			expect(header).to be(:include?, 'accept-language')
		end
		
		it "uses normalised lower case keys" do
			expect(header).not.to be(:include?, 'Accept-Language')
		end
	end
end
