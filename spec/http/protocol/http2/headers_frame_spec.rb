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

require 'http/protocol/http2/headers_frame'
require_relative 'frame_examples'

RSpec.describe HTTP::Protocol::HTTP2::HeadersFrame do
	let(:priority) {HTTP::Protocol::HTTP2::Priority.new(true, 42, 7)}
	let(:data) {"Hello World!"}
	
	it_behaves_like HTTP::Protocol::HTTP2::Frame do
		before do
			subject.set_flags(HTTP::Protocol::HTTP2::END_HEADERS)
			subject.pack priority, data
		end
	end
	
	describe '#pack' do
		it "adds appropriate padding" do
			subject.pack nil, data
			
			expect(subject.length).to be == 256
			expect(subject).to_not be_priority
		end
		
		it "packs priority with no padding" do
			subject.pack priority, data, padding_length: 0
			
			expect(priority.pack.size).to be == 5
			expect(subject.length).to be == (5 + data.bytesize)
		end
	end
	
	describe '#unpack' do
		it "removes padding" do
			subject.pack nil, data
			
			expect(subject.unpack).to be == [nil, data]
		end
	end
	
	describe '#continuation' do
		it "generates chain of frames" do
			subject.pack nil, "Hello World", maximum_length: 8
			
			expect(subject.length).to eq 8
			expect(subject.continuation).to_not be_nil
			expect(subject.continuation.length).to eq 3
		end
	end
end
