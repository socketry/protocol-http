# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Dan Olson.
# Copyright, 2023-2024, by Samuel Williams.

require "protocol/http/body/reader"
require "protocol/http/body/buffered"

require "tempfile"

class TestReader
	include Protocol::HTTP::Body::Reader
	
	def initialize(body)
		@body = body
	end
	
	attr :body
end

describe Protocol::HTTP::Body::Reader do
	let(:body) {Protocol::HTTP::Body::Buffered.wrap("thequickbrownfox")}
	let(:reader) {TestReader.new(body)}
	
	with "#finish" do
		it "returns a buffered representation" do
			expect(reader.finish).to be == body
		end
	end
	
	with "#discard" do
		it "discards the body" do
			expect(body).to receive(:discard)
			expect(reader.discard).to be_nil
		end
	end
	
	with "#buffered!" do
		it "buffers the body" do
			expect(reader.buffered!).to be_equal(reader)
			expect(reader.body).to be == body
		end
	end
	
	with "#close" do
		it "closes the underlying body" do
			expect(body).to receive(:close)
			reader.close
			
			expect(reader).not.to be(:body?)
		end
	end
	
	with "#save" do
		it "saves to the provided filename" do
			Tempfile.create do |file|
				reader.save(file.path)
				expect(File.read(file.path)).to be == "thequickbrownfox"
			end
		end
		
		it "saves by truncating an existing file if it exists" do
			Tempfile.create do |file|
				File.write(file.path, "hello" * 100)
				reader.save(file.path)
				expect(File.read(file.path)).to be == "thequickbrownfox"
			end
		end
		
		it "mirrors the interface of File.open" do
			Tempfile.create do |file|
				reader.save(file.path, "w")
				expect(File.read(file.path)).to be == "thequickbrownfox"
			end
		end
	end
end
