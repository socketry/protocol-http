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
require_relative 'connection_context'
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
			
			expect(subject.padded?).to be_falsey
			expect(subject.length).to be == 16
		end
	end
	
	describe '#unpack' do
		it "unpacks stream_id and data" do
			subject.pack stream_id, data
			
			expect(subject.unpack).to be == [stream_id, data]
		end
	end
	
	context "client/server connection" do
		include_context HTTP::Protocol::HTTP2::Connection
		
		before do
			client.open!
			server.open!
		end
		
		let(:stream) {client.create_stream}
		
		let(:request_headers) do
			[[':method', 'GET'], [':authority', 'Earth'], [':path', '/index.html']]
		end
		
		let(:push_promise_headers) do
			[[':method', 'GET'], [':authority', 'Earth'], [':path', '/index.css']]
		end
		
		it "sends push promise to client" do
			# Client sends a request:
			stream.send_headers(nil, request_headers)
			
			# Server receives request:
			expect(server.read_frame).to be_kind_of HTTP::Protocol::HTTP2::HeadersFrame
			
			# Get the request stream on the server:
			server_stream = server.streams[stream.id]
			
			# Push a promise back through the stream:
			promised_stream = server_stream.send_push_promise(push_promise_headers)
			
			expect(client).to receive(:receive_push_promise).and_wrap_original do |m, *args| stream, headers = m.call(*args)
				
				expect(stream.id).to be == promised_stream.id
				expect(headers).to be == push_promise_headers
			end
			
			expect(client.read_frame).to be_kind_of HTTP::Protocol::HTTP2::PushPromiseFrame
		end
	end
end
