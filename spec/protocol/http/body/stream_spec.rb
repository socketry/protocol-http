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

require 'protocol/http/body/stream'
require 'protocol/http/body/buffered'

RSpec.describe Protocol::HTTP::Body::Stream do
	let(:input) {Protocol::HTTP::Body::Buffered.new(["Hello", "World"])}
	let(:output) {Protocol::HTTP::Body::Buffered.new}
	subject {described_class.new(input, output)}

	describe "#read" do
		it "should read from the input" do
			expect(subject.read(5)).to be == "Hello"
		end

		it "can handle zero-length read" do
			expect(subject.read(0)).to be == ""
		end

		it "can read the entire input" do
			expect(subject.read).to be == "HelloWorld"
		end

		it "should read from the input into the given buffer" do
			buffer = String.new
			expect(subject.read(5, buffer)).to be == "Hello"
			expect(buffer).to be == "Hello"
			expect(subject.read(5, buffer)).to be == "World"
			expect(buffer).to be == "World"
			expect(subject.read(5, buffer)).to be nil
			expect(buffer).to be == ""
		end
		
		it "can read partial input" do
			expect(subject.read(2)).to be == "He"
			expect(subject.read(2)).to be == "ll"
			expect(subject.read(2)).to be == "oW"
			expect(subject.read(2)).to be == "or"
			expect(subject.read(2)).to be == "ld"
			expect(subject.read(2)).to be == nil
		end
	end

	describe "#read_nonblock" do
		it "should read from the input" do
			expect(subject.read_nonblock(5)).to be == "Hello"
			expect(subject.read_nonblock(5)).to be == "World"
			expect(subject.read_nonblock(5)).to be == nil
		end

		it "should read from the input into the given buffer" do
			buffer = String.new
			expect(subject.read_nonblock(5, buffer)).to be == "Hello"
			expect(buffer).to be == "Hello"
			expect(subject.read_nonblock(5, buffer)).to be == "World"
			expect(buffer).to be == "World"
			expect(subject.read_nonblock(5, buffer)).to be nil
			expect(buffer).to be == ""
		end
	end

	describe '#close_read' do
		it "should close the input" do
			subject.close_read
			expect{subject.read(5)}.to raise_error(IOError)
		end
	end

	describe "#write" do
		it "should write to the output" do
			expect(subject.write("Hello")).to be == 5
			expect(subject.write("World")).to be == 5

			expect(output.chunks).to be == ["Hello", "World"]
		end
	end

	describe "#write_nonblock" do
		it "should write to the output" do
			subject.write_nonblock("Hello")
			subject.write_nonblock("World")
			
			expect(output.chunks).to be == ["Hello", "World"]
		end
	end

	describe '#close_write' do
		it "should close the input" do
			subject.close_write
			expect{subject.write("X")}.to raise_error(IOError)
		end
	end

	describe '#flush' do
		it "can be flushed" do	
			# For streams, this is a no-op since buffering is handled by the output body.
			subject.flush
		end
	end

	describe '#close' do
		it "can can be closed" do
			subject.close
			expect(subject).to be_closed
		end

		it "can be closed multiple times" do
			subject.close
			subject.close
			expect(subject).to be_closed
		end
	end
end
