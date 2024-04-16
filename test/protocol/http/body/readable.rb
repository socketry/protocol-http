# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'protocol/http/body/readable'

describe Protocol::HTTP::Body::Readable do
	let(:body) {subject.new}
	
	it "might not be empty" do
		expect(body).not.to be(:empty?)
	end
	
	it "should not be ready" do
		expect(body).not.to be(:ready?)
	end
	
	it "should not be a stream" do
		expect(body).not.to be(:stream?)
	end
	
	with '#finish' do
		it "should return empty buffered representation" do
			expect(body.finish).to be(:empty?)
		end
	end
	
	with '#call' do
		let(:output) {Protocol::HTTP::Body::Buffered.new}
		let(:stream) {Protocol::HTTP::Body::Stream.new(nil, output)}
		
		it "can stream data" do
			body.call(stream)
			
			expect(output).to be(:empty?)
		end
	end
	
	with '#join' do
		it "should be nil" do
			expect(body.join).to be_nil
		end
	end
	
	with "#as_json" do
		it "generates a JSON representation" do
			expect(body.as_json).to have_keys(
				class: be == subject.name,
				length: be_nil,
				stream: be == false,
				ready: be == false,
				empty: be == false,
			)
		end
		
		it "generates a JSON string" do
			expect(JSON.dump(body)).to be == body.to_json
		end
	end
end
