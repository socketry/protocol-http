# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'protocol/http/header/etags'

describe Protocol::HTTP::Header::ETags do
	let(:header) {subject.new(description)}
	
	with "*" do
		it "is a wildcard" do
			expect(header).to be(:wildcard?)
		end
		
		it "matches anything" do
			expect(header).to be(:match?, "anything")
		end
	end
	
	with "abcd" do
		it "is not a wildcard" do
			expect(header).not.to be(:wildcard?)
		end
		
		it "matches itself" do
			expect(header).to be(:match?, "abcd")
		end
		
		it "does not match anything else" do
			expect(header).not.to be(:match?, "anything else")
		end
	end
end
