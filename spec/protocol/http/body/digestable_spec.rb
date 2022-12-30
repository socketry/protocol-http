# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'protocol/http/body/digestable'

RSpec.describe Protocol::HTTP::Body::Digestable do
	let(:source) {Protocol::HTTP::Body::Buffered.new}
	subject {described_class.new(source)}
	
	describe '#digest' do
		before do
			source.write "Hello"
			source.write "World"
		end
		
		it "can compute digest" do
			2.times {subject.read}
			
			expect(subject.digest).to be == "872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4"
		end
		
		it "can recompute digest" do
			expect(subject.read).to be == "Hello"
			expect(subject.digest).to be == "185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969"
			
			expect(subject.read).to be == "World"
			expect(subject.digest).to be == "872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4"
		end
	end
end
