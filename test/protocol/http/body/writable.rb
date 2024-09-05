# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require 'protocol/http/body/writable'
require 'protocol/http/body/a_writable_body'

describe Protocol::HTTP::Body::Writable do
	let(:body) {subject.new}
	
	it_behaves_like Protocol::HTTP::Body::AWritableBody
	
	with "#length" do
		it "should be unspecified by default" do
			expect(body.length).to be_nil
		end
	end
	
	with "#closed?" do
		it "should not be closed by default" do
			expect(body).not.to be(:closed?)
		end
	end
	
	with "#ready?" do
		it "should be ready if chunks are available" do
			expect(body).not.to be(:ready?)
			
			body.write("Hello")
			
			expect(body).to be(:ready?)
		end
		
		it "should be ready if closed" do
			body.close
			
			expect(body).to be(:ready?)
		end
	end
	
	with "#empty?" do
		it "should be empty if closed with no pending chunks" do
			expect(body).not.to be(:empty?)
			
			body.close
			
			expect(body).to be(:empty?)
		end
		
		it "should become empty when pending chunks are read" do
			body.write("Hello")
			body.close
			
			expect(body).not.to be(:empty?)
			body.read
			expect(body).to be(:empty?)
		end
		
		it "should not be empty if chunks are available" do
			body.write("Hello")
			expect(body).not.to be(:empty?)
		end
	end
	
	with "#write" do
		it "should write chunks" do
			body.write("Hello")
			body.write("World")
			
			expect(body.read).to be == "Hello"
			expect(body.read).to be == "World"
		end
		
		it "can't write to closed body" do
			body.close
			
			expect do
				body.write("Hello")
			end.to raise_exception(Protocol::HTTP::Body::Writable::Closed)
		end
	end
end
