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

RSpec.describe HTTP::Protocol::HTTP2::Client do
	include_context HTTP::Protocol::HTTP2::Connection
	
	let(:framer) {client.framer}
	
	let(:client_settings) do
		[[HTTP::Protocol::HTTP2::Settings::HEADER_TABLE_SIZE, 1024]]
	end
	
	let(:server_settings) do
		[[HTTP::Protocol::HTTP2::Settings::HEADER_TABLE_SIZE, 2048]]
	end
	
	it "should start in new state" do
		expect(server.state).to eq :new
	end
	
	it "should receive connection preface followed by settings frame" do
		# The client must write the connection preface followed immediately by the first settings frame:
		framer.write_connection_preface
		
		settings_frame = HTTP::Protocol::HTTP2::SettingsFrame.new
		settings_frame.pack(client_settings)
		framer.write_frame(settings_frame)
		
		expect(server.state).to eq :new
		
		# The server should read the preface and settings...
		server.read_connection_preface(server_settings)
		expect(server.remote_settings.header_table_size).to eq 1024
		
		expect(server.state).to eq :open
		
		# And send an acknowledgement:
		frame = framer.read_frame
		expect(frame).to be_kind_of HTTP::Protocol::HTTP2::SettingsFrame
		expect(frame).to be_acknowledgement
		
		# The server immediatelty sends its own settings frame...
		frame = framer.read_frame
		expect(frame).to be_kind_of HTTP::Protocol::HTTP2::SettingsFrame
		expect(frame.unpack).to eq server_settings
		
		# We reply with acknolwedgement:
		framer.write_frame(frame.acknowledge)
		
		server.read_frame
	end
end
