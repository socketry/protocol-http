# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'protocol/http/body/cacheable'

RSpec.describe Protocol::HTTP::Body::Cacheable do
	include_context RSpec::Memory
	
	let(:body) {Protocol::HTTP::Body::Buffered.new(["Hello", "World"])}
	let(:message) {Protocol::HTTP::Response[200, [], body]}
	
	describe ".wrap" do
		it "can buffer and stream bodies" do
			invoked = false
			
			body = described_class.wrap(message) do
				invoked = true
			end
			
			expect(body.read).to be == "Hello"
			expect(body.read).to be == "World"
			expect(body.read).to be nil
			
			body.close
			
			expect(invoked).to be true
		end
		
		it "ignores failed responses" do
			invoked = false
			
			body = described_class.wrap(message) do
				invoked = true
			end
			
			expect(body.read).to be == "Hello"
			
			body.close(IOError.new("failed"))
			
			expect(invoked).to be false
		end
	end
end
