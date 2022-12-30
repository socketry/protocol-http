# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.
# Copyright, 2020, by Bruno Sutic.

require 'protocol/http/body/buffered'

RSpec.describe Protocol::HTTP::Body::Buffered do
	include_context RSpec::Memory
	
	let(:body) {["Hello", "World"]}
	subject! {described_class.wrap(body)}
	
	describe ".wrap" do
		context "when body is a Body::Readable" do
			let(:body) {Protocol::HTTP::Body::Readable.new}
			
			it "returns the body" do
				expect(subject).to be == body
			end
		end
		
		context "when body is an Array" do
			let(:body) {["Hello", "World"]}
			
			it "returns instance initialized with the array" do
				expect(subject).to be_an_instance_of(described_class)
			end
		end
		
		context "when body responds to #each" do
			let(:body) {["Hello", "World"].each}
			
			it "buffers the content into an array before initializing" do
				expect(subject).to be_an_instance_of(described_class)
				allow(body).to receive(:each).and_raise(StopIteration)
				expect(subject.read).to be == "Hello"
				expect(subject.read).to be == "World"
			end
		end

		context "when body is a String" do
			let(:body) {"Hello World"}

			it "returns instance initialized with the array" do
				expect(subject).to be_an_instance_of(described_class)
			end
		end
	end
	
	describe "#length" do
		it "returns sum of chunks' bytesize" do
			expect(subject.length).to be == 10
		end
	end
	
	describe "#empty?" do
		it "returns false when there are chunks left" do
			expect(subject.empty?).to be == false
			subject.read
			expect(subject.empty?).to be == false
		end
		
		it "returns true when there are no chunks left" do
			subject.read
			subject.read
			expect(subject.empty?).to be == true
		end
		
		it "returns false when rewinded" do
			subject.read
			subject.read
			subject.rewind
			expect(subject.empty?).to be == false
		end
	end
	
	describe '#ready?' do
		it {is_expected.to be_ready}
	end
	
	describe "#finish" do
		it "returns self" do
			expect(subject.finish).to be == subject
		end
	end
	
	describe "#read" do
		it "retrieves chunks of content" do
			expect(subject.read).to be == "Hello"
			expect(subject.read).to be == "World"
			expect(subject.read).to be == nil
		end
		
		context "with large content" do
			let(:content) {Array.new(5) {|i| "#{i}" * (1*1024*1024)}}
			
			it "allocates expected amount of memory" do
				expect do
					subject.read until subject.empty?
				end.to limit_allocations(size: 0)
			end
		end
	end
	
	describe "#rewind" do
		it "positions the cursor to the beginning" do
			expect(subject.read).to be == "Hello"
			subject.rewind
			expect(subject.read).to be == "Hello"
		end
	end

	describe '#inspect' do
		it "can be inspected" do
			expect(subject.inspect).to be =~ /\d+ chunks, \d+ bytes/
		end
	end
end
