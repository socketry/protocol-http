# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'protocol/http/headers'
require 'protocol/http/cookie'

describe Protocol::HTTP::Header::Connection do
	let(:header) {subject.new(description)}
	
	with "close" do
		it "should indiciate connection will be closed" do
			expect(header).to be(:close?)
		end
		
		it "should indiciate connection will not be keep-alive" do
			expect(header).not.to be(:keep_alive?)
		end
	end
	
	with "keep-alive" do
		it "should indiciate connection will not be closed" do
			expect(header).not.to be(:close?)
		end
		
		it "should indiciate connection is not keep-alive" do
			expect(header).to be(:keep_alive?)
		end
	end
	
	with "upgrade" do
		it "should indiciate connection can be upgraded" do
			expect(header).to be(:upgrade?)
		end
	end
end
