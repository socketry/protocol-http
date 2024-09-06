#!/usr/bin/env ruby

require 'async'
require 'async/http/client'
require 'async/http/server'
require 'async/http/endpoint'

require 'protocol/http/body/stream'
require 'protocol/http/body/writable'

endpoint = Async::HTTP::Endpoint.parse('http://localhost:3000')

Async do
	server = Async::HTTP::Server.for(endpoint) do |request|
		output = Protocol::HTTP::Body::Writable.new
		stream = Protocol::HTTP::Body::Stream.new(request.body, output)
		
		Async do
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
	
	input = Protocol::HTTP::Body::Writable.new
	response = client.get("/", body: input)
	
	begin
		stream = Protocol::HTTP::Body::Stream.new(response.body, input)
		
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
ensure
	server_task.stop
end
