# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'protocol/http/body/file'

describe Protocol::HTTP::Body::File do
	let(:path) {File.expand_path('file_spec.txt', __dir__)}
	
	with 'entire file' do
		let(:body) {subject.open(path)}
		
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
end
