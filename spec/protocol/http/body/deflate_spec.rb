#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require 'protocol/http/body/buffered'
require 'protocol/http/body/deflate'
require 'protocol/http/body/inflate'

RSpec.describe Protocol::HTTP::Body::Deflate do
	let(:body) {Protocol::HTTP::Body::Buffered.new}
	let(:compressed_body) {Protocol::HTTP::Body::Deflate.for(body)}
	let(:decompressed_body) {Protocol::HTTP::Body::Inflate.for(compressed_body)}
	
	it "should round-trip data" do
		body.write("Hello World!")
		body.close
		
		expect(decompressed_body.join).to be == "Hello World!"
	end
	
	it "should read chunks" do
		body.write("Hello ")
		body.write("World!")
		body.close
		
		expect(body.read).to be == "Hello "
		expect(body.read).to be == "World!"
		expect(body.read).to be == nil
	end
	
	it "should round-trip chunks" do
		body.write("Hello ")
		body.write("World!")
		body.close
		
		expect(decompressed_body.read).to be == "Hello "
		expect(decompressed_body.read).to be == "World!"
		expect(decompressed_body.read).to be == nil
	end
end
