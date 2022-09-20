require 'protocol/http/body/reader'

RSpec.describe Protocol::HTTP::Body::Reader do
	class TestReader
		include Protocol::HTTP::Body::Reader

		def initialize(body)
			@body = body
		end
	end

	subject do
		TestReader.new(%w(the quick brown fox))
	end

	describe '#save' do
		let(:path) { File.expand_path('reader_spec.txt', __dir__) }

		before do
			File.open(path, 'w') {}
		end

		it 'saves to the provided filename' do
			expect { subject.save(path) }
				.to change { File.read(path) }
				.from('')
				.to('thequickbrownfox')
		end

		it 'mirrors the interface of File.open' do
			expect { subject.save(path, nil, mode: 'w') }
				.to change { File.read(path) }
				.from('')
				.to('thequickbrownfox')
		end
	end
end
