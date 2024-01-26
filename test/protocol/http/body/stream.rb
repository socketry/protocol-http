# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require 'protocol/http/body/stream'
require 'protocol/http/body/buffered'

describe Protocol::HTTP::Body::Stream do
	let(:input) {Protocol::HTTP::Body::Buffered.new(["Hello", "World"])}
	let(:output) {Protocol::HTTP::Body::Buffered.new}
	let(:stream) {subject.new(input, output)}
	
	with 'no input' do
		let(:input) {nil}
		
		it "should be empty" do
			expect(stream).to be(:empty?)
		end
		
		it "should read nothing" do
			expect(stream.read).to be == ""
		end
	end
	
	with '#empty?' do
		it "should be empty" do
			expect(stream).to be(:empty?)
		end
	end
	
	with "#read" do
		it "should read from the input" do
			expect(stream.read(5)).to be == "Hello"
		end
		
		it "can handle zero-length read" do
			expect(stream.read(0)).to be == ""
		end
		
		it "can read the entire input" do
			expect(stream.read).to be == "HelloWorld"
		end
		
		it "should read from the input into the given buffer" do
			buffer = String.new
			expect(stream.read(5, buffer)).to be == "Hello"
			expect(buffer).to be == "Hello"
			expect(stream.read(5, buffer)).to be == "World"
			expect(buffer).to be == "World"
			expect(stream.read(5, buffer)).to be == nil
			expect(buffer).to be == ""
		end
		
		it "can read partial input" do
			expect(stream.read(2)).to be == "He"
			expect(stream.read(2)).to be == "ll"
			expect(stream.read(2)).to be == "oW"
			expect(stream.read(2)).to be == "or"
			expect(stream.read(2)).to be == "ld"
			expect(stream.read(2)).to be == nil
		end
		
		it "can read partial input into the given buffer" do
			buffer = String.new
			expect(stream.read(100, buffer)).to be == "HelloWorld"
			expect(buffer).to be == "HelloWorld"
			
			expect(stream.read(2, buffer)).to be == nil
			expect(buffer).to be == ""
		end
	end
	
	with "#read_nonblock" do
		it "should read from the input" do
			expect(stream.read_nonblock(5)).to be == "Hello"
			expect(stream.read_nonblock(5)).to be == "World"
			expect(stream.read_nonblock(5)).to be == nil
		end
		
		it "should read from the input into the given buffer" do
			buffer = String.new
			expect(stream.read_nonblock(5, buffer)).to be == "Hello"
			expect(buffer).to be == "Hello"
			expect(stream.read_nonblock(5, buffer)).to be == "World"
			expect(buffer).to be == "World"
			expect(stream.read_nonblock(5, buffer)).to be == nil
			expect(buffer).to be == ""
		end
		
		it "can read input into the given buffer" do
			buffer = String.new
			expect(stream.read_nonblock(100, buffer)).to be == "Hello"
			expect(buffer).to be == "Hello"
			
			expect(stream.read_nonblock(100, buffer)).to be == "World"
			expect(buffer).to be == "World"
			
			expect(stream.read_nonblock(2, buffer)).to be == nil
			expect(buffer).to be == ""
		end
		
		it "can read partial input" do
			expect(stream.read_nonblock(2)).to be == "He"
			expect(stream.read_nonblock(2)).to be == "ll"
			expect(stream.read_nonblock(2)).to be == "o"
			expect(stream.read_nonblock(2)).to be == "Wo"
			expect(stream.read_nonblock(2)).to be == "rl"
			expect(stream.read_nonblock(2)).to be == "d"
			expect(stream.read_nonblock(2)).to be == nil
		end
	end
	
	with '#read_partial' do
		it "can read partial input" do
			expect(stream.read_partial(2)).to be == "He"
			expect(stream.read_partial(2)).to be == "ll"
			expect(stream.read_partial(2)).to be == "o"
			expect(stream.read_partial(2)).to be == "Wo"
			expect(stream.read_partial(2)).to be == "rl"
			expect(stream.read_partial(2)).to be == "d"
			expect(stream.read_partial(2)).to be == nil
		end
	end
	
	with '#readpartial' do
		it "can read partial input" do
			expect(stream.readpartial(20)).to be == "Hello"
			expect(stream.readpartial(20)).to be == "World"
			expect{stream.readpartial(20)}.to raise_exception(EOFError)
		end
	end
	
	with '#close_read' do
		it "should close the input" do
			stream.read(1)
			stream.close_read
			expect{stream.read(1)}.to raise_exception(IOError)
		end
	end
	
	with "#write" do
		it "should write to the output" do
			expect(stream.write("Hello")).to be == 5
			expect(stream.write("World")).to be == 5
			
			expect(output.chunks).to be == ["Hello", "World"]
		end
	end
	
	with '#<<' do
		it "should write to the output" do
			stream << "Hello"
			stream << "World"
			
			expect(output.chunks).to be == ["Hello", "World"]
		end
	end
	
	with "#write_nonblock" do
		it "should write to the output" do
			stream.write_nonblock("Hello")
			stream.write_nonblock("World")
			
			expect(output.chunks).to be == ["Hello", "World"]
		end
	end
	
	with '#close_write' do
		it "should close the input" do
			stream.close_write
			expect{stream.write("X")}.to raise_exception(IOError)
		end
	end
	
	with '#flush' do
		it "can be flushed" do	
			# For streams, this is a no-op since buffering is handled by the output body.
			stream.flush
		end
	end
	
	with '#close' do
		it "can can be closed" do
			stream.close
			expect(stream).to be(:closed?)
		end
		
		it "can be closed multiple times" do
			stream.close
			stream.close
			expect(stream).to be(:closed?)
		end
	end
end
