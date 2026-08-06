# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.

require "protocol/http/body/stream"
require "protocol/http/body/readable"

describe Protocol::HTTP::Body::Readable do
	let(:body) {subject.new}
	
	with "#to_io" do
		let(:body) {Protocol::HTTP::Body::Buffered.new(["Hello", "World"])}
		
		it "returns an IO-compatible stream" do
			stream = body.to_io
			
			expect(stream).to be_a(Protocol::HTTP::Body::Stream)
			expect(stream.output).to be_nil
			expect(body.to_io).not.to be_equal(stream)
			expect(stream.read(5)).to be == "Hello"
			expect(stream.read(5)).to be == "World"
			expect(stream.read(5)).to be_nil
			expect{stream.write("!")}.to raise_exception(IOError)
		end
	end
	
	it "might not be empty" do
		expect(body).not.to be(:empty?)
	end
	
	it "should not be ready" do
		expect(body).not.to be(:ready?)
	end
	
	with "#buffered" do
		it "is unable to buffer by default" do
			expect(body.buffered).to be_nil
		end
	end
	
	with "#finish" do
		it "should return empty buffered representation" do
			expect(body.finish).to be(:empty?)
		end
	end
	
	with "#each" do
		it "passes a read error to close" do
			error = RuntimeError.new("Could not read the body!")
			closed_error = nil
			
			mock(body) do |mock|
				mock.replace(:read){raise error}
				mock.replace(:close){|argument = nil| closed_error = argument}
			end
			
			raised_error = begin
				body.each{}
			rescue => exception
				exception
			end
			
			expect(raised_error).to be_equal(error)
			expect(closed_error).to be_equal(error)
		end
		
		it "passes a consumer error to close" do
			error = RuntimeError.new("Could not consume the body!")
			closed_error = nil
			chunks = ["Hello", nil]
			
			mock(body) do |mock|
				mock.replace(:read){chunks.shift}
				mock.replace(:close){|argument = nil| closed_error = argument}
			end
			
			raised_error = begin
				body.each{raise error}
			rescue => exception
				exception
			end
			
			expect(raised_error).to be_equal(error)
			expect(closed_error).to be_equal(error)
		end
	end
	
	with "#call" do
		let(:output) {Protocol::HTTP::Body::Buffered.new}
		let(:stream) {Protocol::HTTP::Body::Stream.new(nil, output)}
		
		it "can stream (empty) data" do
			body.call(stream)
			
			expect(output).to be(:empty?)
		end
		
		it "flushes the stream if it is not ready" do
			chunks = ["Hello World"]
			
			mock(body) do |mock|
				mock.replace(:read) do
					chunks.pop
				end
				
				mock.replace(:ready?) do
					false
				end
			end
			
			expect(stream).to receive(:flush)
			
			body.call(stream)
		end
		
		it "closes a plain IO normally when reading fails" do
			error = RuntimeError.new("Could not read the body!")
			stream = StringIO.new
			
			mock(body) do |mock|
				mock.replace(:read){raise error}
			end
			
			raised_error = begin
				body.call(stream)
			rescue => exception
				exception
			end
			
			expect(raised_error).to be_equal(error)
			expect(stream).to be(:closed?)
		end
		
		it "passes a read error to a stream with explicit error closure" do
			error = RuntimeError.new("Could not read the body!")
			closed_error = nil
			stream = Object.new
			stream.define_singleton_method(:close_with_error){|argument| closed_error = argument}
			
			mock(body) do |mock|
				mock.replace(:read){raise error}
			end
			
			raised_error = begin
				body.call(stream)
			rescue => exception
				exception
			end
			
			expect(raised_error).to be_equal(error)
			expect(closed_error).to be_equal(error)
		end
		
	end
	
	with "#join" do
		it "should be nil" do
			expect(body.join).to be_nil
		end
	end
	
	with "#discard" do
		it "should read all chunks" do
			expect(body).to receive(:read).and_return(nil)
			expect(body.discard).to be_nil
		end
	end
	
	with "#as_json" do
		it "generates a JSON representation" do
			expect(body.as_json).to have_keys(
				class: be == subject.name,
				length: be_nil,
				stream: be == false,
				ready: be == false,
				empty: be == false,
			)
		end
		
		it "generates a JSON string" do
			expect(JSON.dump(body)).to be == body.to_json
		end
	end
	
	with "#rewindable?" do
		it "is not rewindable" do
			expect(body).not.to be(:rewindable?)
			expect(body.rewind).to be == false
		end
	end
end
