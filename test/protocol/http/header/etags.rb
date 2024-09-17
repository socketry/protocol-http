# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.
# Copyright, 2023, by Thomas Morgan.

require "protocol/http/header/etags"

describe Protocol::HTTP::Header::ETags do
	let(:header) {subject.new(description)}
	
	with "*" do
		it "is a wildcard" do
			expect(header).to be(:wildcard?)
		end
		
		it "matches anything" do
			expect(header).to be(:match?, '"anything"')
		end
	end
	
	with '"abcd"' do
		it "is not a wildcard" do
			expect(header).not.to be(:wildcard?)
		end
		
		it "matches itself" do
			expect(header).to be(:match?, '"abcd"')
		end
		
		it "strongly matches only another strong etag" do
			expect(header).to be(:strong_match?, '"abcd"')
			expect(header).not.to be(:strong_match?, 'W/"abcd"')
		end
		
		it "weakly matches both weak and strong etags" do
			expect(header).to be(:weak_match?, '"abcd"')
			expect(header).to be(:weak_match?, 'W/"abcd"')
		end
		
		it "does not match anything else" do
			expect(header).not.to be(:match?, '"anything else"')
		end
	end
	
	with 'W/"abcd"' do
		it "never strongly matches" do
			expect(header).not.to be(:strong_match?, '"abcd"')
			expect(header).not.to be(:strong_match?, 'W/"abcd"')
		end
		
		it "weakly matches both weak and strong etags" do
			expect(header).to be(:weak_match?, '"abcd"')
			expect(header).to be(:weak_match?, 'W/"abcd"')
		end
	end
end
