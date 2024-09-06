#!/usr/bin/env ruby

require 'async'
require 'async/http/client'
require 'async/http/server'
require 'async/http/endpoint'

require 'protocol/http/body/streamable'
require 'protocol/http/body/writable'
require 'protocol/http/body/stream'

endpoint = Async::HTTP::Endpoint.parse('http://localhost:3000')

Async do
	server = Async::HTTP::Server.for(endpoint) do |request|
		output = Protocol::HTTP::Body::Streamable.response(request) do |stream|
			# Simple echo server:
			while chunk = stream.readpartial(1024)
				stream.write(chunk)
			end
		rescue EOFError
			# Ignore EOF errors.
		ensure
			stream.close
		end
		
		Protocol::HTTP::Response[200, {}, output]
	end
	
	server_task = Async{server.run}
	
	client = Async::HTTP::Client.new(endpoint)
	
	streamable = Protocol::HTTP::Body::Streamable.request do |stream|
		stream.write("Hello, ")
		stream.write("World!")
		stream.close_write
		
		while chunk = stream.readpartial(1024)
			puts chunk
		end
	rescue EOFError
		# Ignore EOF errors.
	ensure
		stream.close
	end
	
	response = client.get("/", body: streamable)
	streamable.stream(response.body)
ensure
	server_task.stop
end
