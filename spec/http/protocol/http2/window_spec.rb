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

require_relative 'connection_context'

RSpec.describe HTTP::Protocol::HTTP2::Window do
	include_context HTTP::Protocol::HTTP2::Connection
	
	let(:framer) {client.framer}
	
	let(:settings) do
		[[HTTP::Protocol::HTTP2::Settings::INITIAL_WINDOW_SIZE, 200]]
	end
	
	let(:headers) do
		[[':method', 'GET'], [':authority', 'Earth']]
	end
	
	let(:stream) do
		HTTP::Protocol::HTTP2::Stream.new(client)
	end
	
	it "should send connection preface followed by settings frame" do
		client.send_connection_preface([])
		server.read_connection_preface(settings)
		client.read_frame
		client.read_frame
		server.read_frame
		
		expect(client.remote_settings.initial_window_size).to eq 200
		expect(server.local_settings.initial_window_size).to eq 200
		
		stream.send_headers(nil, headers)
		server.read_frame
		
		# Write 60 bytes of data.
		stream.send_data("*" * 60)
		
		expect(server.read_frame).to be_kind_of HTTP::Protocol::HTTP2::DataFrame
		
		# Write another 60 bytes which passes the 50% threshold.
		stream.send_data("*" * 60)
		
		# The server receives a data frame...
		expect(server.read_frame).to be_kind_of HTTP::Protocol::HTTP2::DataFrame
		
		# ...and must respond with a window update:
		frame = client.read_frame
		expect(frame).to be_kind_of HTTP::Protocol::HTTP2::WindowUpdateFrame
		
		expect(frame.unpack).to eq 120
	end
end
