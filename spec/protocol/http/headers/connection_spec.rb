# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require 'protocol/http/headers'
require 'protocol/http/cookie'

RSpec.describe Protocol::HTTP::Header::Connection do
	context "connection: close" do
		subject {described_class.new("close")}
		
		it "should indiciate connection will be closed" do
			expect(subject).to be_close
		end
		
		it "should indiciate connection will not be keep-alive" do
			expect(subject).to_not be_keep_alive
		end
	end
	
	context "connection: keep-alive" do
		subject {described_class.new("keep-alive")}
		
		it "should indiciate connection will not be closed" do
			expect(subject).to_not be_close
		end
		
		it "should indiciate connection is not keep-alive" do
			expect(subject).to be_keep_alive
		end
	end
	
	context "connection: upgrade" do
		subject {described_class.new("upgrade")}
		
		it "should indiciate connection can be upgraded" do
			expect(subject).to be_upgrade
		end
	end
end
