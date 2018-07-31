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
	
	let(:framer) {server.framer}
	
	let(:settings) do
		[[HTTP::Protocol::HTTP2::Settings::HEADER_TABLE_SIZE, 1024]]
	end
	
	it "should start in new state" do
		expect(client.state).to eq :new
	end
	
	it "should send connection preface followed by settings frame" do
		client.send_connection_preface(settings) do
			expect(framer.read_connection_preface).to eq HTTP::Protocol::HTTP2::CONNECTION_PREFACE_MAGIC
			
			client_settings_frame = framer.read_frame
			expect(client_settings_frame).to be_kind_of HTTP::Protocol::HTTP2::SettingsFrame
			expect(client_settings_frame.unpack).to eq settings
			
			# Fake (empty) server settings:
			server_settings_frame = HTTP::Protocol::HTTP2::SettingsFrame.new
			server_settings_frame.pack
			framer.write_frame(server_settings_frame)
			
			framer.write_frame(client_settings_frame.acknowledge)
		end
		
		expect(client.state).to eq :new
		
		client.read_frame
		
		expect(client.state).to eq :open
		expect(client.local_settings.header_table_size).to eq 1024
	end
end
