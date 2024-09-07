# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'protocol/http/body/streamable'

describe Protocol::HTTP::Body::Streamable do
	let(:block) do
		proc do |stream|
			stream.write("Hello")
			stream.write("World")
			stream.close
		end
	end
	
	let(:body) {subject.new(block)}
	
	with "#stream?" do
		it "should be streamable" do
			expect(body).to be(:stream?)
		end
	end
	
	with '#block' do
		it "should wrap block" do
			expect(body.block).to be == block
		end
	end
	
	with '#read' do
		it "can read the body" do
			expect(body.read).to be == "Hello"
			expect(body.read).to be == "World"
			expect(body.read).to be == nil
		end
		
		with "block that doesn't close" do
			let(:block) do
				proc do |stream|
					stream.write("Hello")
					stream.write("World")
				end
			end
			
			it "can read the body" do
				expect(body.read).to be == "Hello"
				expect(body.read).to be == "World"
				expect(body.read).to be == nil
			end
		end
		
		with "a block that allows stream to escape" do
			let(:block) do
				proc do |stream|
					@stream = stream
				end
			end
			
			it "can read the body" do
				expect(body.read).to be == nil
				
				expect do
					@stream.write("!")
				end.to raise_exception(RuntimeError, message: be =~ /Stream is not being read!/)
			end
		end
	end
	
	with '#close_write' do
		let(:block) do
			proc do |stream|
				stream.close_write
			end
		end
		
		let(:body) {subject.new(block)}
		
		it "can close the output body" do
			expect(body.read).to be == nil
		end
	end
	
	with '#each' do
		it "can read the body" do
			chunks = []
			body.each{|chunk| chunks << chunk}
			expect(chunks).to be == ["Hello", "World"]
		end
	end
	
	with '#call' do
		it "can read the body" do
			stream = StringIO.new
			body.call(stream)
			expect(stream.string).to be == "HelloWorld"
		end
		
		with "a block that raises an error" do
			let(:block) do
				proc do |stream|
					stream.write("Hello")
					
					raise "Oh no... a wild error appeared!"
				ensure
					stream.close
				end
			end
			
			it "closes the stream if an error occurs" do
				stream = StringIO.new
				expect(body).to receive(:close)
				
				expect do
					body.call(stream)
				end.to raise_exception(RuntimeError, message: be =~ /Oh no... a wild error appeared!/)
				
				expect(stream.string).to be == "Hello"
				
				body.stream(nil)
			end
		end
	end
	
	with '#close' do
		it "can close the body" do
			expect(body.read).to be == "Hello"
			body.close
		end
	end
	
	with "nested fiber" do
		let(:block) do
			proc do |stream|
				Fiber.new do
					stream.write("Hello")
				end.resume
			end
		end
		
		it "can read a chunk" do
			expect(body.read).to be == "Hello"
		end
	end
	
	with "buffered input" do
		let(:input) {Protocol::HTTP::Body::Buffered.new(["Hello", " ", "World"])}
		
		let(:block) do
			proc do |stream|
				while chunk = stream.read_partial
					stream.write(chunk)
				end
			end
		end
		
		let(:body) {subject.new(block, input)}
		
		it "can read from input" do
			expect(body.read).to be == "Hello"
			expect(body.read).to be == " "
			expect(body.read).to be == "World"
		end
		
		it "can stream to output" do
			output = StringIO.new
			stream = Protocol::HTTP::Body::Stream.new(input, output)
			
			body.call(stream)
			
			expect(output.string).to be == "Hello World"
		end
	end
end
