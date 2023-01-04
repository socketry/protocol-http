# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'protocol/http/body/digestable'
require 'protocol/http/body/buffered'

describe Protocol::HTTP::Body::Digestable do
	let(:source) {Protocol::HTTP::Body::Buffered.new}
	let(:body) {subject.new(source)}
	
	it "should not be a stream" do
		expect(body).not.to be(:stream?)
	end
	
	with '.wrap' do
		let(:source) {Protocol::HTTP::Body::Buffered.wrap("HelloWorld")}
		let(:message) {Protocol::HTTP::Request.new(nil, nil, 'GET', '/', nil, Protocol::HTTP::Headers.new, body)}
		
		it "can wrap a message" do
			Protocol::HTTP::Body::Digestable.wrap(message) do |digestable|
				expect(digestable).to have_attributes(
					digest: be == "872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4",
				)
			end
			
			expect(message.body.join).to be == "HelloWorld"
		end
	end
	
	with '#digest' do
		def before
			source.write "Hello"
			source.write "World"
			
			super
		end
		
		it "can compute digest" do
			2.times {body.read}
			
			expect(body.digest).to be == "872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4"
		end
		
		it "can recompute digest" do
			expect(body.read).to be == "Hello"
			expect(body.digest).to be == "185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969"
			
			expect(body.read).to be == "World"
			expect(body.digest).to be == "872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4"
			
			expect(body.etag).to be == '"872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4"'
			expect(body.etag(weak: true)).to be == 'W/"872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4"'
		end
	end
end
