# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "protocol/http/peer"
require "socket"

describe Protocol::HTTP::Peer do
	it "can be created from IO" do
		address = Addrinfo.tcp("192.168.1.1", 80)
		io = Socket.new(:AF_INET, :SOCK_STREAM)
		expect(io).to receive(:remote_address).and_return(address)
		
		peer = Protocol::HTTP::Peer.for(io)
		expect(peer).to have_attributes(
			address: be_equal(address),
		)
	end
end