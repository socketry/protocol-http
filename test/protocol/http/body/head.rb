# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2023, by Samuel Williams.

require 'protocol/http/body/head'
require 'protocol/http/body/buffered'

describe Protocol::HTTP::Body::Head do
	with "zero length" do
		let(:body) {subject.new(0)}
		
		it "should be ready" do
			expect(body).to be(:ready?)
		end
		
		it "should be empty" do
			expect(body).to be(:empty?)
		end
		
		with '#join' do
			it "should be nil" do
				expect(body.join).to be_nil
			end
		end
	end
	
	with "non-zero length" do
		let(:body) {subject.new(1)}
		
		it "should be empty" do
			expect(body).to be(:empty?)
		end
		
		with '#read' do
			it "should be nil" do
				expect(body.join).to be_nil
			end
		end
		
		with '#join' do
			it "should be nil" do
				expect(body.join).to be_nil
			end
		end
	end
	
	with '.for' do
		let(:source) {Protocol::HTTP::Body::Buffered.wrap("!")}
		let(:body) {subject.for(source)}
		
		it "captures length and closes existing body" do
			expect(source).to receive(:close)
			
			expect(body).to have_attributes(length: be == 1)
			body.close
		end
	end
end
