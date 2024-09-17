#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "async"
require "async/http/client"
require "async/http/server"
require "async/http/endpoint"

require "protocol/http/body/stream"
require "protocol/http/body/writable"

def make_server(endpoint)
	Async::HTTP::Server.for(endpoint) do |request|
		output = Protocol::HTTP::Body::Writable.new
		stream = Protocol::HTTP::Body::Stream.new(request.body, output)
		
		Async do
			stream.write("Hello, ")
			stream.write("World!")
			
			stream.close_write
			
			# Simple echo server:
			$stderr.puts "Server reading chunks..."
			while chunk = stream.readpartial(1024)
				puts chunk
			end
		rescue EOFError
			# Ignore EOF errors.
		ensure
			stream.close
		end
		
		Protocol::HTTP::Response[200, {}, output]
	end
end

Async do |task|
	endpoint = Async::HTTP::Endpoint.parse("http://localhost:3000")
	
	server_task = task.async{make_server(endpoint).run}
	
	client = Async::HTTP::Client.new(endpoint)
	
	input = Protocol::HTTP::Body::Writable.new
	response = client.get("/", body: input)
	
	begin
		stream = Protocol::HTTP::Body::Stream.new(response.body, input)
		
		$stderr.puts "Client echoing chunks..."
		while chunk = stream.readpartial(1024)
			stream.write(chunk)
		end
	rescue EOFError
		# Ignore EOF errors.
	ensure
		stream.close
	end
ensure
	server_task.stop
end
