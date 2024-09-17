# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "protocol/http/body/streamable"
require "sus/fixtures/async"

describe Protocol::HTTP::Body::Streamable do
	include Sus::Fixtures::Async::ReactorContext
	
	let(:block) do
		proc do |stream|
			stream.write("Hello")
			stream.write("World")
			stream.close
		end
	end
	
	let(:body) {subject.request(&block)}
	
	with ".request" do
		it "can create a new body" do
			body = subject.request(&block)
			expect(body).to be_a(Protocol::HTTP::Body::Streamable::RequestBody)
		end
	end
	
	with ".response" do
		let(:request) {Protocol::HTTP::Request.new("GET", "/")}
		
		it "can create a new body" do
			body = subject.response(request, &block)
			expect(body).to be_a(Protocol::HTTP::Body::Streamable::Body)
		end
	end
	
	with "#stream?" do
		it "should be streamable" do
			expect(body).to be(:stream?)
		end
	end
	
	with "#read" do
		it "can read the body" do
			expect(body.read).to be == "Hello"
			expect(body.read).to be == "World"
			expect(body.read).to be == nil
		end
	end
	
	with "#close_write" do
		let(:block) do
			proc do |stream|
				stream.close_write
			end
		end
		
		it "can close the output body" do
			expect(body.read).to be == nil
		end
	end
	
	with "#each" do
		it "can read the body" do
			chunks = []
			body.each{|chunk| chunks << chunk}
			expect(chunks).to be == ["Hello", "World"]
		end
	end
	
	with "#call" do
		it "can read the body" do
			stream = StringIO.new
			body.call(stream)
			expect(stream.string).to be == "HelloWorld"
		end
		
		it "will fail if invoked twice" do
			stream = StringIO.new
			body.call(stream)
			
			expect do
				body.call(stream)
			end.to raise_exception(Protocol::HTTP::Body::Streamable::ConsumedError)
		end
		
		it "will fail if trying to read after streaming" do
			stream = StringIO.new
			body.call(stream)
			
			expect do
				body.read
			end.to raise_exception(Protocol::HTTP::Body::Streamable::ConsumedError)
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
				
				expect do
					body.call(stream)
				end.to raise_exception(RuntimeError, message: be =~ /Oh no... a wild error appeared!/)
				
				expect(stream.string).to be == "Hello"
			end
		end
	end
	
	with "#close" do
		it "can close the body" do
			expect(body.read).to be == "Hello"
			
			body.close
		end
		
		it "can raise an error on the block" do
			expect(body.read).to be == "Hello"
			body.close(RuntimeError.new("Oh no!"))
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
		
		let(:response) {Protocol::HTTP::Response[200, body: input]}
		let(:body) {subject.response(response, &block)}
		
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
		
		with "#close" do
			it "can close the body" do
				expect(input).not.to receive(:close)
				
				expect(body.read).to be == "Hello"
				body.close
			end
		end
	end
	
	with "#stream" do
		let(:block) do
			proc do |stream|
				while chunk = stream.read_partial
					stream.write(chunk)
				end
			rescue => error
			ensure
				stream.close(error)
			end
		end
		
		it "can stream to output" do
			input = Protocol::HTTP::Body::Buffered.new(["Hello", " ", "World"])
			
			body.stream(input)
			
			expect(body.read).to be == "Hello"
			expect(body.read).to be == " "
			expect(body.read).to be == "World"
			
			body.close
		end
		
		it "can stream to output with an error" do
			input = Protocol::HTTP::Body::Buffered.new(["Hello", " ", "World"])
			
			mock(input) do |mock|
				mock.replace(:read) do
					raise "Oh no!"
				end
			end
			
			body.stream(input)
			
			expect do
				body.read
			end.to raise_exception(RuntimeError, message: be =~ /Oh no!/)
		end
	end
	
	with "streaming in a different task" do
		let(:block) do
			proc do |stream|
				while chunk = stream.read_partial
					stream.write(chunk)
				end
			rescue => error
			ensure
				stream.close(error)
			end
		end
		
		let(:input) {Protocol::HTTP::Body::Writable.new}
		let(:output) {Protocol::HTTP::Body::Writable.new}
		
		before do
			parent = Async::Task.current
			
			@input_task = parent.async do
				body.stream(input)
			end
			
			@output_task = parent.async do
				while chunk = body.read
					output.write(chunk)
				end
			rescue => error
			ensure
				output.close_write(error)
			end
		end
		
		after do
			@input_task&.wait
			@output_task&.wait
		end
		
		it "can stream a chunk" do
			input.write("Hello")
			input.close_write
			expect(output.read).to be == "Hello"
		end
		
		it "can stream multiple chunks" do
			input.write("Hello")
			input.write(" ")
			input.write("World")
			input.close_write
			
			expect(output.read).to be == "Hello"
			expect(output.read).to be == " "
			expect(output.read).to be == "World"
		end
		
		it "can stream an error" do
			input.write("Hello")
			input.close_write(RuntimeError.new("Oh no!"))
			
			expect do
				output.read
			end.to raise_exception(RuntimeError, message: be =~ /Oh no!/)
		end
	end
end
