# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
	
	describe "#each" do
		let(:result) { [] }
		
		context "when passed a block" do
			it "iterates over chunks" do
				subject.each { |chunk| result << chunk }
				expect(result).to be == body
			end
		end
		
		context "without a block" do
			it "returns an enumerator" do
				expect(subject.each).to be_a(Enumerator)
			end
			
			it "can be chained with enumerator methods" do
				subject.each.with_index do |chunk, index|
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
end
