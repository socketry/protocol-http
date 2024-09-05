# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'protocol/http/body/file'

describe Protocol::HTTP::Body::File do
	let(:path) {File.expand_path('file_spec.txt', __dir__)}
	let(:body) {subject.open(path)}
	
	with '#stream?' do
		it "should be streamable" do
			expect(body).to be(:stream?)
		end
	end
	
	with '#join' do
		it "should read entire file" do
			expect(body.join).to be == "Hello World"
		end
	end
	
	with '#close' do
		it "should close file" do
			expect(body.file).to receive(:close)
			
			body.close
			
			expect(body).to be(:empty?)
		end
	end
	
	with '#rewind' do
		it "should rewind file" do
			expect(body.read).to be == "Hello World"
			expect(body).to be(:empty?)
			
			body.rewind
			
			expect(body).not.to be(:empty?)
			expect(body.read).to be == "Hello World"
		end
	end
	
	with '#inspect' do
		it "generates a string representation" do
			expect(body.inspect).to be =~ /Protocol::HTTP::Body::File file=(.*?) offset=\d+ remaining=\d+/
		end
	end
	
	with 'entire file' do
		it "should read entire file" do
			expect(body.read).to be == "Hello World"
		end
		
		it "should use binary encoding" do
			expect(::File).to receive(:open).with(path, ::File::RDONLY | ::File::BINARY)
			
			chunk = body.read
			
			expect(chunk.encoding).to be == Encoding::BINARY
		end
		
		with '#ready?' do
			it "should be ready" do
				expect(body).to be(:ready?)
			end
		end
	end
	
	with 'partial file' do
		let(:body) {subject.open(path, 2...4)}
		
		it "should read specified range" do
			expect(body.read).to be == "ll"
		end
	end
	
	with "#call" do
		let(:output) {StringIO.new}
		
		it "can stream output" do
			body.call(output)
			
			expect(output.string).to be == "Hello World"
		end
	end
end
