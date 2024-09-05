#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'protocol/http/body/buffered'
require 'protocol/http/body/deflate'
require 'protocol/http/body/inflate'

require 'securerandom'

describe Protocol::HTTP::Body::Deflate do
	let(:body) {Protocol::HTTP::Body::Buffered.new}
	let(:compressed_body) {Protocol::HTTP::Body::Deflate.for(body)}
	let(:decompressed_body) {Protocol::HTTP::Body::Inflate.for(compressed_body)}
	
	it "should round-trip data" do
		body.write("Hello World!")
		body.close
		
		expect(decompressed_body.join).to be == "Hello World!"
	end
	
	let(:data) {"Hello World!" * 10_000}
	
	it "should round-trip data" do
		body.write(data)
		body.close
		
		expect(decompressed_body.read).to be == data
		expect(decompressed_body.read).to be == nil
		
		expect(compressed_body.ratio).to be < 1.0
		expect(decompressed_body.ratio).to be > 1.0
	end
	
	it "should round-trip chunks" do
		10.times do
			body.write("Hello World!")
		end
		body.close
		
		10.times do
			expect(decompressed_body.read).to be == "Hello World!"
		end
		expect(decompressed_body.read).to be == nil
	end
	
	with '#inspect' do
		it "can generate string representation" do
			expect(compressed_body.inspect).to be == "#<Protocol::HTTP::Body::Buffered 0 chunks, 0 bytes> | #<Protocol::HTTP::Body::Deflate 100.0%>"
		end
	end
end
