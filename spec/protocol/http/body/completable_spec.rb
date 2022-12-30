# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2022, by Samuel Williams.

require 'protocol/http/body/completable'

RSpec.describe Protocol::HTTP::Body::Completable do
	let(:source) {Protocol::HTTP::Body::Buffered.new}
	let(:callback) {double}
	subject {described_class.new(source, callback)}
	
	it "can trigger callback when finished reading" do
		expect(callback).to receive(:call)
		
		expect(subject.read).to be_nil
		
		subject.close
	end
end
