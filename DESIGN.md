# Middleware Design

`Body::Writable` is a queue of String chunks.

## Request Response Model

~~~ruby
class Request
	attr :verb
	attr :target
	attr :body
end

class Response
	attr :status
	attr :headers
	attr :body
end

def call(request)
	return response
end

def call(request)
	return @app.call(request)
end
~~~

## Stream Model

~~~ruby
class Stream
	attr :verb
	attr :target
	
	def respond(status, headers) = ...
	
	attr_accessor :input
	attr_accessor :output
end

class Response
	def initialize(verb, target)
		@input = Body::Writable.new
		@output = Body::Writable.new
	end
	
	def request(verb, target)
		# Create a request stream suitable for writing into the buffered response:
		Stream.new(verb, target, @input, @output)
	end
	
	def write(...)
		@input.write(...)
	end
	
	def read
		@output.read
	end
end

def call(stream)
	# nothing. maybe error
end

def call(stream)
	return @app.call(stream)
end
~~~

# Client Design

## Request Response Model

~~~ruby
request = Request.new("GET", url)
response = call(request)

response.headers
response.read
~~~

## Stream Model

~~~ruby
response = Response.new
call(response.request("GET", url))

response.headers
response.read
~~~

## Differences

The request/response model has a symmetrical design which naturally uses the return value for the result of executing the request. The result encapsulates the behaviour of how to read the response status, headers and body. Because of that, streaming input and output becomes a function of the result object itself. As in:

~~~ruby
def call(request)
	body = Body::Writable.new
	
	Fiber.schedule do
		while chunk = request.input.read
			body.write(chunk.reverse)
		end
	end
	
	return Response[200, [], body]
end

input = Body::Writable.new
response = call(... body ...)

input.write("Hello World")
input.close
response.read -> "dlroW olleH"
~~~

The streaming model does not have the same symmetry, and instead opts for a uni-directional flow of information.

~~~ruby
def call(stream)
	Fiber.schedule do
		while chunk = stream.read
			stream.write(chunk.reverse)
		end
	end
end

input = Body::Writable.new
response = Response.new(...input...)
call(response.stream)

input.write("Hello World")
input.close
response.read -> "dlroW olleH"
~~~

The value of this uni-directional flow is that it is natural for the stream to be taken out of the scope imposed by the nested `call(request)` model. However, the user must explicitly close the stream, since it's no longer scoped to the client and/or server.
