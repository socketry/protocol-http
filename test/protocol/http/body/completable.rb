# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'protocol/http/body/completable'
require 'protocol/http/body/buffered'

describe Protocol::HTTP::Body::Completable do
	let(:body) {Protocol::HTTP::Body::Buffered.new}
	let(:callback) {Proc.new{}}
	let(:completable) {subject.new(body, callback)}
	
	it "can trigger callback when finished reading" do
		expect(callback).to receive(:call)
		
		expect(completable.read).to be_nil
		completable.close
	end
	
	AnImmediateCallback = Sus::Shared("an immediate callback") do
		it "invokes block immediately" do
			invoked = false
			
			wrapped = subject.wrap(message) do
				invoked = true
			end
			
			expect(invoked).to be == true
			expect(message.body).to be_equal(body)
		end
	end
	
	ADeferredCallback = Sus::Shared("a deferred callback") do
		it "invokes block when body is finished reading" do
			invoked = false
			
			wrapped = subject.wrap(message) do
				invoked = true
			end
			
			expect(invoked).to be == false
			expect(message.body).to be_equal(wrapped)
			
			wrapped.join
			
			expect(invoked).to be == true
		end
	end
	
	with '.wrap' do
		let(:message) {Protocol::HTTP::Request.new(nil, nil, 'GET', '/', nil, Protocol::HTTP::Headers.new, body)}
		
		with 'empty body' do
			it_behaves_like AnImmediateCallback
		end
		
		with 'nil body' do
			let(:body) {nil}
			
			it_behaves_like AnImmediateCallback
		end
		
		with 'non-empty body' do
			let(:body) {Protocol::HTTP::Body::Buffered.wrap('Hello World')}
			
			it_behaves_like ADeferredCallback
		end
	end
	
	with '#finish' do
		it "invokes callback once" do
			expect(callback).to receive(:call)
			
			2.times do
				completable.finish
			end
		end
	end
end
