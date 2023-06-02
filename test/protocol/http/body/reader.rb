# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Dan Olson.
# Copyright, 2023, by Samuel Williams.

require 'protocol/http/body/reader'

class TestReader
	include Protocol::HTTP::Body::Reader

	def initialize(body)
		@body = body
	end
end

describe Protocol::HTTP::Body::Reader do
	let(:body) {Protocol::HTTP::Body::Buffered.wrap('thequickbrownfox')}
	let(:reader) {TestReader.new(body)}
	
	with '#finish' do
		it 'returns a buffered representation' do
			expect(reader.finish).to be == body
		end
	end
	
	with '#close' do
		it 'closes the underlying body' do
			expect(body).to receive(:close)
			reader.close
			
			expect(reader).not.to be(:body?)
		end
	end
	
	with '#save' do
		let(:path) { File.expand_path('reader_spec.txt', __dir__) }
		
		it 'saves to the provided filename' do
			reader.save(path)
			expect(File.read(path)).to be == 'thequickbrownfox'
		end
		
		it 'saves by truncating an existing file if it exists' do
			File.write(path, 'hello' * 100)
			reader.save(path)
			expect(File.read(path)).to be == 'thequickbrownfox'
		end
		
		it 'mirrors the interface of File.open' do
			reader.save(path, 'w')
			expect(File.read(path)).to be == 'thequickbrownfox'
		end
	end
end
