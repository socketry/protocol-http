# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require 'protocol/http/body/rewindable'
require 'protocol/http/request'

describe Protocol::HTTP::Body::Rewindable do
	let(:source) {Protocol::HTTP::Body::Buffered.new}
	let(:body) {subject.new(source)}
	
	it "can write and read data" do
		3.times do |i|
			source.write("Hello World #{i}")
			expect(body.read).to be == "Hello World #{i}"
		end
	end
	
	it "can write and read data multiple times" do
		3.times do |i|
			source.write("Hello World #{i}")
		end
		
		3.times do
			body.rewind
			
			expect(body).to be(:ready?)
			expect(body.read).to be == "Hello World 0"
		end
	end
	
	it "can buffer data in order" do
		3.times do |i|
			source.write("Hello World #{i}")
		end
		
		2.times do
			body.rewind
			
			3.times do |i|
				expect(body.read).to be == "Hello World #{i}"
			end
		end
	end
	
	with ".wrap" do
		with "a buffered body" do
			let(:body) {Protocol::HTTP::Body::Buffered.new}
			let(:message) {Protocol::HTTP::Request.new(nil, nil, 'GET', '/', nil, Protocol::HTTP::Headers.new, body)}
			
			it "returns the body" do
				expect(subject.wrap(message)).to be == body
			end
		end
		
		with "a non-rewindable body" do
			let(:body) {Protocol::HTTP::Body::Readable.new}
			let(:message) {Protocol::HTTP::Request.new(nil, nil, 'GET', '/', nil, Protocol::HTTP::Headers.new, body)}
			
			it "returns a new rewindable body" do
				expect(subject.wrap(message)).to be_a(Protocol::HTTP::Body::Rewindable)
			end
		end
	end
	
	with '#buffered' do
		it "can generate buffered representation" do
			3.times do |i|
				source.write("Hello World #{i}")
			end
			
			expect(body.buffered).to be(:empty?)
			
			# Read one chunk into the internal buffer:
			body.read
			
			expect(body.buffered.chunks).to be == ["Hello World 0"]
		end
	end
	
	with '#empty?' do
		it "can read and re-read the body" do
			source.write("Hello World")
			expect(body).not.to be(:empty?)
			
			expect(body.read).to be == "Hello World"
			expect(body).to be(:empty?)

			body.rewind
			expect(body.read).to be == "Hello World"
			expect(body).to be(:empty?)
		end
	end
	
	with "#rewindable?" do
		it "is rewindable" do
			expect(body).to be(:rewindable?)
		end
	end
	
	with '#inspect' do
		it "can generate string representation" do
			expect(body.inspect).to be == "#<Protocol::HTTP::Body::Rewindable 0/0 chunks read>"
		end
	end
end
