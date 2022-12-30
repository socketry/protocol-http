# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2022, by Samuel Williams.

require 'protocol/http/headers'

RSpec.describe Protocol::HTTP::Headers::Merged do	
	let(:fields) do
		[
			['Content-Type', 'text/html'],
			['Set-Cookie', 'hello=world'],
			['Accept', '*/*'],
			['content-length', 10],
		]
	end
	
	subject{described_class.new(fields)}
	let(:headers) {Protocol::HTTP::Headers.new(subject)}
	
	describe '#each' do
		it 'should yield keys as lower case' do
			subject.each do |key, value|
				expect(key).to be == key.downcase
			end
		end
		
		it 'should yield values as strings' do
			subject.each do |key, value|
				expect(value).to be_kind_of String
			end
		end
	end
	
	describe '#<<' do
		it "can append fields" do
			subject << [["Accept", "image/jpeg"]]
			
			expect(headers['accept']).to be == ['*/*', 'image/jpeg']
		end
	end
end
