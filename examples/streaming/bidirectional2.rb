#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2026, by Samuel Williams.

require "async"
require "async/http/client"
require "async/http/server"
require "async/http/endpoint"

require "protocol/http/body/streamable"
require "protocol/http/body/writable"
require "protocol/http/body/stream"

endpoint = Async::HTTP::Endpoint.parse("http://localhost:3000")

Async do
	server = Async::HTTP::Server.for(endpoint) do |request|
		output = Protocol::HTTP::Body::Streamable.response(request) do |stream|
			$stderr.puts "Server writing chunks..."
			stream.write("Hello, ")
			stream.write("World!")
			
			$stderr.puts "Server reading chunks..."
			while chunk = stream.readpartial(1024)
				puts chunk
			end
		rescue EOFError
			$stderr.puts "Server EOF."
			# Ignore EOF errors.
		ensure
			$stderr.puts "Server closing stream."
			stream.close
		end
		
		Protocol::HTTP::Response[200, {}, output]
	end
	
	server_task = Async {server.run}
	
	client = Async::HTTP::Client.new(endpoint)
	
	streamable = Protocol::HTTP::Body::Streamable.request do |stream|
		# Simple echo client:
		while chunk = stream.readpartial(1024)
			$stderr.puts "Client chunk: #{chunk.inspect}"
			stream.write(chunk)
			$stderr.puts "Client waiting for next chunk..."
		end
	rescue EOFError
		$stderr.puts "Client EOF."
		# Ignore EOF errors.
	ensure
		$stderr.puts "Client closing stream."
		stream.close
	end
	
	$stderr.puts "Client sending request..."
	response = client.get("/", body: streamable)
	$stderr.puts "Client received response and streaming it..."
	streamable.stream(response.body)
	$stderr.puts "Client done streaming response."
ensure
	server_task.stop
end
