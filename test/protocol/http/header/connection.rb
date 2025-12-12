# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2024, by Thomas Morgan.

require "protocol/http/headers"
require "protocol/http/cookie"

describe Protocol::HTTP::Header::Connection do
	let(:header) {subject.parse(description)}
	
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
	
	with "close, keep-alive" do
		it "should prioritize close over keep-alive" do
			expect(header).to be(:close?)
			expect(header).not.to be(:keep_alive?)
		end
	end
	
	with "upgrade" do
		it "should indiciate connection can be upgraded" do
			expect(header).to be(:upgrade?)
		end
	end
	
	with "#<<" do
		let(:header) {subject.new}
		
		it "can append values" do
			header << "close"
			expect(header).to be(:close?)
			
			header << "upgrade"
			expect(header).to be(:upgrade?)
			
			expect(header.to_s).to be == "close,upgrade"
		end
	end
	
	with "normalization" do
		it "normalizes to lowercase when initialized with string" do
			header = subject.new("CLOSE, UPGRADE")
			expect(header).to be(:include?, "close")
			expect(header).to be(:include?, "upgrade")
			expect(header).not.to be(:include?, "CLOSE")
			expect(header).not.to be(:include?, "UPGRADE")
		end
		
		it "normalizes to lowercase when initialized with array" do
			header = subject.new(["CLOSE", "UPGRADE"])
			expect(header).to be(:include?, "close")
			expect(header).to be(:include?, "upgrade")
			expect(header).not.to be(:include?, "CLOSE")
			expect(header).not.to be(:include?, "UPGRADE")
		end
		
		it "raises ArgumentError for invalid value types" do
			expect{subject.new(123)}.to raise_exception(ArgumentError)
		end
	end
end
