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

require 'http/protocol/http2/push_promise_frame'
require_relative 'frame_examples'

RSpec.describe HTTP::Protocol::HTTP2::PushPromiseFrame do
	let(:stream_id) {5}
	let(:data) {"Hello World!"}
	
	it_behaves_like HTTP::Protocol::HTTP2::Frame do
		before do
			subject.set_flags(HTTP::Protocol::HTTP2::END_HEADERS)
			subject.pack stream_id, data
		end
	end
	
	describe '#pack' do
		it "packs stream_id and data with padding" do
			subject.pack stream_id, data
			
			expect(subject.padded?).to be_truthy
			expect(subject.length).to be == 31
		end
	end
	
	describe '#unpack' do
		it "unpacks stream_id and data" do
			subject.pack stream_id, data
			
			expect(subject.unpack).to be == [stream_id, data]
		end
	end
end
