# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Dan Olson.
# Copyright, 2022-2023, by Samuel Williams.

require 'protocol/http/body/reader'

class TestReader
	include Protocol::HTTP::Body::Reader

	def initialize(body)
		@body = body
	end
end

describe Protocol::HTTP::Body::Reader do
	let(:reader) {TestReader.new(%w(the quick brown fox))}
	
	with '#save' do
		let(:path) { File.expand_path('reader_spec.txt', __dir__) }
		
		it 'saves to the provided filename' do
			reader.save(path)
			expect(File.read(path)).to be == 'thequickbrownfox'
		end

		it 'mirrors the interface of File.open' do
			reader.save(path, nil, mode: 'w')
			expect(File.read(path)).to be == 'thequickbrownfox'
		end
	end
end
