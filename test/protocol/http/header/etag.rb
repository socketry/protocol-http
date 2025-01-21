# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require "protocol/http/header/etag"

describe Protocol::HTTP::Header::ETag do
	let(:header) {subject.new(description)}
	
	with 'W/"abcd"' do
		it "is weak" do
			expect(header).to be(:weak?)
		end
	end
	
	with '"abcd"' do
		it "is not weak" do
			expect(header).not.to be(:weak?)
		end
	end
	
	with "#<<" do
		let(:header) {subject.new}
		
		it "can replace values" do
			header << '"abcd"'
			expect(header).not.to be(:weak?)
			
			header << 'W/"abcd"'
			expect(header).to be(:weak?)
		end
	end
end
