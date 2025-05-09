#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "protocol/http/body/buffered"
require "protocol/http/body/deflate"
require "protocol/http/body/inflate"

require "securerandom"

describe Protocol::HTTP::Body::Deflate do
	let(:body) {Protocol::HTTP::Body::Buffered.new}
	let(:compressed_body) {Protocol::HTTP::Body::Deflate.for(body)}
	let(:decompressed_body) {Protocol::HTTP::Body::Inflate.for(compressed_body)}
	
	it "should round-trip data" do
		body.write("Hello World!")
		
		expect(decompressed_body.join).to be == "Hello World!"
	end
	
	let(:data) {"Hello World!" * 10_000}
	
	it "should round-trip data" do
		body.write(data)
		
		expect(decompressed_body.read).to be == data
		expect(decompressed_body.read).to be == nil
		
		expect(compressed_body.ratio).to be < 1.0
		expect(decompressed_body.ratio).to be > 1.0
	end
	
	it "should round-trip chunks" do
		10.times do
			body.write("Hello World!")
		end
		
		10.times do
			expect(decompressed_body.read).to be == "Hello World!"
		end
		expect(decompressed_body.read).to be == nil
	end
	
	with "#length" do
		it "should be unknown" do
			expect(compressed_body).to have_attributes(
				length: be_nil,
			)
			
			expect(decompressed_body).to have_attributes(
				length: be_nil,
			)
		end
	end
	
	with "#inspect" do
		it "can generate string representation" do
			expect(compressed_body.inspect).to be == "#<Protocol::HTTP::Body::Buffered 0 chunks, 0 bytes> | #<Protocol::HTTP::Body::Deflate 100.0%>"
		end
	end
end
