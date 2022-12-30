# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require 'protocol/http/body/file'

RSpec.describe Protocol::HTTP::Body::File do
	let(:path) {File.expand_path('file_spec.txt', __dir__)}
	
	context 'entire file' do
		subject {described_class.open(path)}
		
		it "should read entire file" do
			expect(subject.read).to be == "Hello World"
		end
		
		it "should use binary encoding" do
			expect(::File).to receive(:open).with(path, ::File::RDONLY | ::File::BINARY).and_call_original
			
			chunk = subject.read
			
			expect(chunk.encoding).to be == Encoding::BINARY
		end
		
		describe '#ready?' do
			it {is_expected.to be_ready}
		end
	end
	
	context 'partial file' do
		subject {described_class.open(path, 2...4)}
		
		it "should read specified range" do
			expect(subject.read).to be == "ll"
		end
	end
end
