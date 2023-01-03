# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'protocol/http/headers'

describe Protocol::HTTP::Headers::Merged do	
	let(:fields) do
		[
			['Content-Type', 'text/html'],
			['Set-Cookie', 'hello=world'],
			['Accept', '*/*'],
			['content-length', 10],
		]
	end
	
	let(:merged) {subject.new(fields)}
	let(:headers) {Protocol::HTTP::Headers.new(merged)}
	
	with '#each' do
		it 'should yield keys as lower case' do
			merged.each do |key, value|
				expect(key).to be == key.downcase
			end
		end
		
		it 'should yield values as strings' do
			merged.each do |key, value|
				expect(value).to be_a(String)
			end
		end
	end
	
	with '#<<' do
		it "can append fields" do
			merged << [["Accept", "image/jpeg"]]
			
			expect(headers['accept']).to be == ['*/*', 'image/jpeg']
		end
	end
end
