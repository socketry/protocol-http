# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require 'protocol/http/header/authorization'
require 'protocol/http/headers'

RSpec.describe Protocol::HTTP::Header::Authorization do
	context 'with basic username/password' do
		subject {described_class.basic("samuel", "password")}
		
		it "should generate correct authorization header" do
			expect(subject).to be == "Basic c2FtdWVsOnBhc3N3b3Jk"
		end
		
		describe '#credentials' do
			it "can split credentials" do
				expect(subject.credentials).to be == ["Basic", "c2FtdWVsOnBhc3N3b3Jk"]
			end
		end
	end
end
