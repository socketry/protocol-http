# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2020-2023, by Bruno Sutic.

require "protocol/http/body/buffered"
require "protocol/http/body/a_readable_body"

describe Protocol::HTTP::Body::Buffered do
	let(:source) {["Hello", "World"]}
	let(:body) {subject.wrap(source)}
	
	it_behaves_like Protocol::HTTP::Body::AReadableBody
	
	with ".wrap" do
		with "an instance of Protocol::HTTP::Body::Readable as a source" do
			let(:source) {Protocol::HTTP::Body::Readable.new}
			
			it "returns the body" do
				expect(body).to be == source
			end
		end
		
		with "an instance of an Array as a source" do
			let(:source) {["Hello", "World"]}
			
			it "returns instance initialized with the array" do
				expect(body).to be_a(subject)
			end
		end
		
		with "source that responds to #each" do
			let(:source) {["Hello", "World"].each}
			
			it "buffers the content into an array before initializing" do
				expect(body).to be_a(subject)
				expect(body.read).to be == "Hello"
				expect(body.read).to be == "World"
			end
		end
		
		with "an instance of a String as a source" do
			let(:source) {"Hello World"}
			
			it "returns instance initialized with the String" do
				expect(body).to be_a(subject)
				expect(body.read).to be == "Hello World"
			end
		end
	end
	
	with "#length" do
		it "returns sum of chunks' bytesize" do
			expect(body.length).to be == 10
		end
	end
	
	with "#empty?" do
		it "returns false when there are chunks left" do
			expect(body.empty?).to be == false
			body.read
			expect(body.empty?).to be == false
		end
		
		it "returns true when there are no chunks left" do
			body.read
			body.read
			expect(body.empty?).to be == true
		end
		
		it "returns false when rewinded" do
			body.read
			body.read
			body.rewind
			expect(body.empty?).to be == false
		end
	end
	
	with "#ready?" do
		it "is ready when chunks are available" do
			expect(body).to be(:ready?)
		end
	end
	
	with "#finish" do
		it "returns self" do
			expect(body.finish).to be == body
		end
	end
	
	with "#call" do
		let(:output) {Protocol::HTTP::Body::Buffered.new}
		let(:stream) {Protocol::HTTP::Body::Stream.new(nil, output)}
		
		it "can stream data" do
			body.call(stream)
			
			expect(output).not.to be(:empty?)
			expect(output.chunks).to be == source
		end
	end
	
	with "#read" do
		it "retrieves chunks of content" do
			expect(body.read).to be == "Hello"
			expect(body.read).to be == "World"
			expect(body.read).to be == nil
		end
		
		# with "large content" do
		# 	let(:content) {Array.new(5) {|i| "#{i}" * (1*1024*1024)}}
		
		# 	it "allocates expected amount of memory" do
		# 		expect do
		# 			subject.read until subject.empty?
		# 		end.to limit_allocations(size: 0)
		# 	end
		# end
	end
	
	with "#rewind" do
		it "is rewindable" do
			expect(body).to be(:rewindable?)
		end
		
		it "positions the cursor to the beginning" do
			expect(body.read).to be == "Hello"
			body.rewind
			expect(body.read).to be == "Hello"
		end
	end
	
	with "#buffered" do
		let(:buffered_body) {body.buffered}
		
		it "returns a buffered body" do
			expect(buffered_body).to be_a(subject)
			expect(buffered_body.read).to be == "Hello"
			expect(buffered_body.read).to be == "World"
		end
		
		it "doesn't affect the original body" do
			expect(buffered_body.join).to be == "HelloWorld"
			
			expect(buffered_body).to be(:empty?)
			expect(body).not.to be(:empty?)
		end
	end
	
	with "#inspect" do
		let(:body) {subject.new}
		
		it "generates string representation for empty body" do
			expect(body.inspect).to be == "#<Protocol::HTTP::Body::Buffered empty>"
		end
	end
	
	with "#each" do
		with "a block" do
			it "iterates over chunks" do
				result = []
				body.each{|chunk| result << chunk}
				expect(result).to be == source
			end
		end
		
		with "no block" do
			it "returns an enumerator" do
				expect(body.each).to be_a(Enumerator)
			end
			
			it "can be chained with enumerator methods" do
				result = []
				
				body.each.with_index do |chunk, index|
					if index.zero?
						result << chunk.upcase
					else
						result << chunk.downcase
					end
				end
				
				expect(result).to be == ["HELLO", "world"]
			end
		end
	end
	
	with "#clear" do
		it "clears all chunks and resets length" do
			body.clear
			expect(body.chunks).to be(:empty?)
			expect(body.read).to be == nil
			expect(body.length).to be == 0
		end
	end
	
	with "#inspect" do
		it "can be inspected" do
			expect(body.inspect).to be =~ /\d+ chunks, \d+ bytes/
		end
	end
	
	with "#discard" do
		it "closes the body" do
			expect(body).to receive(:close)
			
			expect(body.discard).to be == nil
		end
	end
end
