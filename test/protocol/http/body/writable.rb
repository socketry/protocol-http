# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "protocol/http/body/writable"
require "protocol/http/body/deflate"
require "protocol/http/body/a_writable_body"

describe Protocol::HTTP::Body::Writable do
	let(:body) {subject.new}
	
	it_behaves_like Protocol::HTTP::Body::AWritableBody
	
	with "#length" do
		it "should be unspecified by default" do
			expect(body.length).to be_nil
		end
	end
	
	with "#closed?" do
		it "should not be closed by default" do
			expect(body).not.to be(:closed?)
		end
	end
	
	with "#ready?" do
		it "should be ready if chunks are available" do
			expect(body).not.to be(:ready?)
			
			body.write("Hello")
			
			expect(body).to be(:ready?)
		end
		
		it "should be ready if closed" do
			body.close
			
			expect(body).to be(:ready?)
		end
	end
	
	with "#empty?" do
		it "should be empty if closed with no pending chunks" do
			expect(body).not.to be(:empty?)
			
			body.close_write
			
			expect(body).to be(:empty?)
		end
		
		it "should become empty when pending chunks are read" do
			body.write("Hello")
			
			body.close_write
			
			expect(body).not.to be(:empty?)
			body.read
			expect(body).to be(:empty?)
		end
		
		it "should not be empty if chunks are available" do
			body.write("Hello")
			expect(body).not.to be(:empty?)
		end
	end
	
	with "#write" do
		it "should write chunks" do
			body.write("Hello")
			body.write("World")
			
			expect(body.read).to be == "Hello"
			expect(body.read).to be == "World"
		end
		
		it "can't write to closed body" do
			body.close
			
			expect do
				body.write("Hello")
			end.to raise_exception(Protocol::HTTP::Body::Writable::Closed)
		end
		
		it "can write and read data" do
			3.times do |i|
				body.write("Hello World #{i}")
				expect(body.read).to be == "Hello World #{i}"
			end
		end
		
		it "can buffer data in order" do
			3.times do |i|
				body.write("Hello World #{i}")
			end
			
			3.times do |i|
				expect(body.read).to be == "Hello World #{i}"
			end
		end
	end
	
	with "#join" do
		it "can join chunks" do
			3.times do |i|
				body.write("#{i}")
			end
			
			body.close_write
			
			expect(body.join).to be == "012"
		end
	end
	
	with "#each" do
		it "can read all data in order" do
			3.times do |i|
				body.write("Hello World #{i}")
			end
			
			body.close_write
			
			3.times do |i|
				chunk = body.read
				expect(chunk).to be == "Hello World #{i}"
			end
		end
		
		it "can propagate failures" do
			body.write("Beep boop") # This will cause a failure.
			
			expect do
				body.each do |chunk|
					raise RuntimeError.new("It was too big!")
				end
			end.to raise_exception(RuntimeError, message: be =~ /big/)
			
			expect do
				body.write("Beep boop") # This will fail.
			end.to raise_exception(RuntimeError, message: be =~ /big/)
		end
		
		it "can propagate failures in nested bodies" do
			nested = ::Protocol::HTTP::Body::Deflate.for(body)
			
			body.write("Beep boop") # This will cause a failure.
			
			expect do
				nested.each do |chunk|
					raise RuntimeError.new("It was too big!")
				end
			end.to raise_exception(RuntimeError, message: be =~ /big/)
			
			expect do
				body.write("Beep boop") # This will fail.
			end.to raise_exception(RuntimeError, message: be =~ /big/)
		end
		
		it "will stop after finishing" do
			body.write("Hello World!")
			body.close_write
			
			expect(body).not.to be(:empty?)
			
			body.each do |chunk|
				expect(chunk).to be == "Hello World!"
			end
			
			expect(body).to be(:empty?)
		end
	end
	
	with "#output" do
		it "can be used to write data" do
			body.output do |output|
				output.write("Hello World!")
			end
			
			expect(body.output).to be(:closed?)
			
			expect(body.read).to be == "Hello World!"
			expect(body.read).to be_nil
		end
		
		it "can propagate errors" do
			expect do
				body.output do |output|
					raise "Oops!"
				end
			end.to raise_exception(RuntimeError, message: be =~ /Oops/)
			
			expect(body).to be(:closed?)
			
			expect do
				body.read
			end.to raise_exception(RuntimeError, message: be =~ /Oops/)
		end
	end
end
