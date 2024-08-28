#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'protocol/http/body/buffered'
require 'protocol/http/body/deflate'
require 'protocol/http/body/inflate'

require 'securerandom'

describe Protocol::HTTP::Body::Inflate do
	let(:sample) {"The quick brown fox jumps over the lazy dog."}
	let(:chunks) {[sample] * 1024}
	
	let(:body) {Protocol::HTTP::Body::Buffered.new(chunks)}
	let(:deflate_body) {Protocol::HTTP::Body::Deflate.for(body)}
	let(:compressed_chunks) {deflate_body.join.each_char.to_a}
	let(:compressed_body_chunks) {compressed_chunks}
	let(:compressed_body) {Protocol::HTTP::Body::Buffered.new(compressed_body_chunks)}
	let(:decompressed_body) {subject.for(compressed_body)}
	
	it "can decompress a body" do
		expect(decompressed_body.join).to be == chunks.join
	end
	
	with "incomplete input" do
		let(:compressed_body_chunks) {compressed_chunks.first(compressed_chunks.size/2)}
		
		it "raises error when input is incomplete" do
			expect{decompressed_body.join}.to raise_exception(Zlib::BufError)
		end
	end
end
