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

require 'http/protocol/http2/client'
require 'http/protocol/http2/server'
require 'http/protocol/http2/stream'

require 'socket'

RSpec.describe HTTP::Protocol::HTTP2::Connection do
	let(:io) {Socket.pair(Socket::PF_UNIX, Socket::SOCK_STREAM)}
	
	subject(:client) {HTTP::Protocol::HTTP2::Client.new(HTTP::Protocol::HTTP2::Framer.new(io.first))}
	let(:server) {HTTP::Protocol::HTTP2::Server.new(HTTP::Protocol::HTTP2::Framer.new(io.last))}
	
	context HTTP::Protocol::HTTP2::PingFrame do
		it "can send ping and receive pong" do
			expect(server).to receive(:receive_ping).once.and_call_original
			
			client.send_ping("12345678")
			
			server.read_frame
			
			expect(client).to receive(:receive_ping).once.and_call_original
			
			frame = client.read_frame
		end
	end
	
	context HTTP::Protocol::HTTP2::Stream do
		let(:stream) {HTTP::Protocol::HTTP2::Stream.new(client)}
		let(:headers) {[[':method', 'GET'], [':path', '/'], [':authority', 'localhost']]}
		
		it "can create new stream and send response" do
			client.streams[stream.id] = stream
			stream.send_headers(nil, headers)
			expect(stream.id).to eq 1
			
			expect(server).to receive(:receive_headers).once.and_call_original
			server.read_frame
			expect(server.streams).to_not be_empty
			
			expect(server.streams[1].headers).to eq headers
			expect(server.streams[1].state).to eq :open
			
			stream.send_data(nil)
			expect(stream.state).to eq :half_closed_local
			
			server.read_frame
			expect(server.streams[1].state).to eq :half_closed_remote
			
			server.streams[1].send_headers(nil, [[':status', '200']], HTTP::Protocol::HTTP2::END_STREAM)
			client.read_frame
			expect(stream.state).to eq :closed
		end
	end
end
