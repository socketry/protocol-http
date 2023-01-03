# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'protocol/http/body/completable'
require 'protocol/http/body/buffered'

describe Protocol::HTTP::Body::Completable do
	let(:source) {Protocol::HTTP::Body::Buffered.new}
	let(:callback) {Proc.new{}}
	let(:body) {subject.new(source, callback)}
	
	it "can trigger callback when finished reading" do
		expect(callback).to receive(:call)
		
		expect(body.read).to be_nil
		body.close
	end
end
