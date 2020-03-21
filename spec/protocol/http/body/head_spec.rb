# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'protocol/http/body/head'

RSpec.describe Protocol::HTTP::Body::Head do
	context "with zero length" do
		subject(:body) {described_class.new(0)}
		
		it {is_expected.to be_empty}
		
		describe '#join' do
			subject {body.join}
			
			it {is_expected.to be_nil}
		end
	end
	
	context "with non-zero length" do
		subject(:body) {described_class.new(1)}
		
		it {is_expected.to_not be_empty}
		
		describe '#read' do
			subject {body.read}
			it {is_expected.to be_nil}
		end
		
		describe '#join' do
			subject {body.join}
			
			it {is_expected.to be_nil}
		end
	end
	
	describe '.for' do
		let(:body) {double}
		subject {described_class.for(body)}
		
		it "captures length and closes existing body" do
			expect(body).to receive(:length).and_return(1)
			expect(body).to receive(:close)
			
			expect(subject).to have_attributes(length: 1)
			
			subject.close
		end
	end
end
