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
end
