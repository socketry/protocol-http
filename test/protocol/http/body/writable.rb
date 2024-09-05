# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'protocol/http/body/writable'
require 'protocol/http/body/a_writable_body'

describe Protocol::HTTP::Body::Writable do
	let(:body) {subject.new}
	
	it_behaves_like Protocol::HTTP::Body::AWritableBody
end
