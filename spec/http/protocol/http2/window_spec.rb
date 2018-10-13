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
	
	before do
		client.send_connection_preface([]) do
			server.read_connection_preface(settings)
		end
		
		client.read_frame until client.state == :open
		server.read_frame until server.state == :open
		
		stream.send_headers(nil, headers)
		expect(server.read_frame).to be_kind_of HTTP::Protocol::HTTP2::HeadersFrame
	end
	
	it "should assign capacity according to settings" do
		expect(client.remote_settings.initial_window_size).to eq 200
		expect(server.local_settings.initial_window_size).to eq 200
		
		expect(client.remote_window.capacity).to eq 0xFFFF
		expect(server.local_window.capacity).to eq 0xFFFF
		
		expect(client.local_window.capacity).to eq 0xFFFF
		expect(server.remote_window.capacity).to eq 0xFFFF
		
		expect(client.local_settings.initial_window_size).to eq 0xFFFF
		expect(server.remote_settings.initial_window_size).to eq 0xFFFF
	end
	
	it "should send window update after exhausting half of the available window" do
		# Write 60 bytes of data.
		stream.send_data("*" * 60)
		
		expect(stream.remote_window.used).to eq 60
		expect(client.remote_window.used).to eq 60
		
		# puts "Server #{server} #{server.remote_window.inspect} reading frame..."
		expect(server.read_frame).to be_kind_of HTTP::Protocol::HTTP2::DataFrame
		expect(server.local_window.used).to eq 60
		
		# Write another 60 bytes which passes the 50% threshold.
		stream.send_data("*" * 60)
		
		# The server receives a data frame...
		expect(server.read_frame).to be_kind_of HTTP::Protocol::HTTP2::DataFrame
		
		# ...and must respond with a window update:
		frame = client.read_frame
		expect(frame).to be_kind_of HTTP::Protocol::HTTP2::WindowUpdateFrame
		
		expect(frame.unpack).to eq 120
	end
	
	context '#window_updated' do
		it "should be invoked when window update is received" do
			# Write 200 bytes of data (client -> server) which exhausts server local window
			stream.send_data("*" * 200)
			
			expect(server.read_frame).to be_kind_of HTTP::Protocol::HTTP2::DataFrame
			
			expect(server.local_window.used).to eq 200
			expect(client.remote_window.used).to eq 200
			
			# Window update was sent, and used data was zeroed:
			server_stream = server.streams[stream.id]
			expect(server_stream.local_window.used).to eq 0
			
			# ...and must respond with a window update for the stream:
			expect(stream).to receive(:window_updated).once
			frame = client.read_frame
			expect(frame).to be_kind_of HTTP::Protocol::HTTP2::WindowUpdateFrame
			expect(frame.unpack).to eq 200
		end
	end
end
