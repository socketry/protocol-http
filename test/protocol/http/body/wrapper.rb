# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'protocol/http/body/readable'

describe Protocol::HTTP::Body::Wrapper do
	let(:source) {Protocol::HTTP::Body::Buffered.new}
	let(:body) {subject.new(source)}
	
	it "should proxy finish" do
		expect(source).to receive(:finish).and_return(nil)
		body.finish
	end
	
	it "should proxy close" do
		expect(source).to receive(:close).and_return(nil)
		body.close
	end
	
	it "should proxy empty?" do
		expect(source).to receive(:empty?).and_return(true)
		expect(body.empty?).to be == true
	end
	
	it "should proxy ready?" do
		expect(source).to receive(:ready?).and_return(true)
		expect(body.ready?).to be == true
	end
	
	it "should proxy length" do
		expect(source).to receive(:length).and_return(1)
		expect(body.length).to be == 1
	end
	
	it "should proxy stream?" do
		expect(source).to receive(:stream?).and_return(true)
		expect(body.stream?).to be == true
	end
	
	it "should proxy read" do
		expect(source).to receive(:read).and_return("!")
		expect(body.read).to be == "!"
	end
	
	it "should proxy inspect" do
		expect(source).to receive(:inspect).and_return("!")
		expect(body.inspect).to be == "!"
	end
	
	it "should proxy call" do
		expect(source).to receive(:call).and_return(nil)
		body.call(nil)
	end
	
	with '.wrap' do
		let(:message) {Protocol::HTTP::Request.new(nil, nil, 'GET', '/', nil, Protocol::HTTP::Headers.new, body)}
		
		it "should wrap body" do
			subject.wrap(message)
			
			expect(message.body).to be_a(Protocol::HTTP::Body::Wrapper)
		end
	end
	
	with "#as_json" do
		it "generates a JSON representation" do
			expect(body.as_json).to have_keys(
				class: be == "Protocol::HTTP::Body::Wrapper",
				body: be == source.as_json
			)
		end
	end
end
