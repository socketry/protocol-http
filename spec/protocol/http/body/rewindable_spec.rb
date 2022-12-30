# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2022, by Samuel Williams.

require 'protocol/http/body/rewindable'

RSpec.describe Protocol::HTTP::Body::Rewindable do
	let(:source) {Protocol::HTTP::Body::Buffered.new}
	subject {described_class.new(source)}
	
	it "can write and read data" do
		3.times do |i|
			source.write("Hello World #{i}")
			expect(subject.read).to be == "Hello World #{i}"
		end
	end
	
	it "can write and read data multiple times" do
		3.times do |i|
			source.write("Hello World #{i}")
		end
		
		3.times do
			subject.rewind
			
			expect(subject.read).to be == "Hello World 0"
		end
	end
	
	it "can buffer data in order" do
		3.times do |i|
			source.write("Hello World #{i}")
		end
		
		2.times do
			subject.rewind
			
			3.times do |i|
				expect(subject.read).to be == "Hello World #{i}"
			end
		end
	end
	
	describe '#empty?' do
		it {is_expected.to be_empty}
		
		context "with unread chunk" do
			before {source.write("Hello World")}
			it {is_expected.to_not be_empty}
		end
		
		context "with read chunk" do
			before do
				source.write("Hello World")
				expect(subject.read).to be == "Hello World"
			end
			
			it {is_expected.to be_empty}
		end
		
		context "with rewound chunk" do
			before do
				source.write("Hello World")
				expect(subject.read).to be == "Hello World"
				subject.rewind
			end
			
			it {is_expected.to_not be_empty}
		end
		
		context "with rewound chunk" do
			before do
				source.write("Hello World")
				expect(subject.read).to be == "Hello World"
				subject.rewind
				expect(subject.read).to be == "Hello World"
			end
			
			it {is_expected.to be_empty}
		end
	end
end
