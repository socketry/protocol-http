# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

require "protocol/http/body/wrapper"
require "protocol/http/body/buffered"
require "protocol/http/request"

require "json"
require "stringio"

describe Protocol::HTTP::Body::Wrapper do
	let(:source) {Protocol::HTTP::Body::Buffered.new}
	let(:body) {subject.new(source)}
	
	with "#stream?" do
		it "should not be streamable" do
			expect(body).not.to be(:stream?)
		end
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
	
	it "should proxy read" do
		expect(source).to receive(:read).and_return("!")
		expect(body.read).to be == "!"
	end
	
	it "should proxy inspect" do
		expect(source).to receive(:inspect).and_return("!")
		expect(body.inspect).to be(:include?, "!")
	end
	
	with ".wrap" do
		let(:message) {Protocol::HTTP::Request.new(nil, nil, "GET", "/", nil, Protocol::HTTP::Headers.new, body)}
		
		it "should wrap body" do
			subject.wrap(message)
			
			expect(message.body).to be_a(Protocol::HTTP::Body::Wrapper)
		end
	end
	
	with "#buffered" do
		it "should proxy buffered" do
			expect(source).to receive(:buffered).and_return(true)
			expect(body.buffered).to be == true
		end
	end
	
	with "#rewindable?" do
		it "should proxy rewindable?" do
			expect(source).to receive(:rewindable?).and_return(true)
			expect(body.rewindable?).to be == true
		end
	end
	
	with "#rewind" do
		it "should proxy rewind" do
			expect(source).to receive(:rewind).and_return(true)
			expect(body.rewind).to be == true
		end
	end
	
	with "#as_json" do
		it "generates a JSON representation" do
			expect(body.as_json).to have_keys(
				class: be == "Protocol::HTTP::Body::Wrapper",
				body: be == source.as_json
			)
		end
		
		it "generates a JSON string" do
			expect(JSON.dump(body)).to be == body.to_json
		end
	end
	
	with "#each" do
		it "should invoke close correctly" do
			expect(body).to receive(:close)
			
			body.each{}
		end
	end
	
	with "#stream" do
		let(:stream) {StringIO.new}
		
		it "should invoke close correctly" do
			expect(body).to receive(:close)
			
			body.call(stream)
		end
	end
	
	with "#discard" do
		it "should proxy discard" do
			expect(source).to receive(:discard).and_return(nil)
			expect(body.discard).to be_nil
		end
	end
end
