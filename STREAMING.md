# Streaming

Streaming is a complex topic given that most server's are not scalable in this respect. A variety of solutions exist to work around limited server implementations, but they impose significant burden on the implementation and are generally incompatible with implementations of HTTP which are not request per connection. We propose to simplify the current Rack implementation to support streaming in a consistent way, but also allow for backwards compatibility with existing servers.

## Current Implementation

Rack currently supports streaming using `rack.hijack`. There are two ways to hijack the underlying socket for a given request: a partial hijack and a full hijack. Not all servers support both modes of operation and neither method is fully compatible with HTTP/2.

### Partial Hijack

A partial hijack allows the web server to respond with the response status, headers, and then yields the stream back to the application code. It does this by using a special `rack.hijack` header:

``` ruby
def call(env)
	body = proc do |stream|
		stream.write("Hello World")
		stream.close
	end
	
	if env['rack.hijack?']
		return [200, {'rack.hijack' => body}, nil]
	end
end
```

- It is not clear whether the body needs to handle the formatting of the response, i.e. chunked encoding, compression, transfer encoding, etc.
- It mixes `rack.` specific headers with normal HTTP headers which is computationally expensive for the server to detect.
- It's not clear what the returned body should be.

### Full Hijack

A full hijack allows the web server to completely take control of the underlying socket. This occurs at the point the `rack.hijack` is invoked.

``` ruby
def call(env)
	if hijack = env['rack.hijack']
		socket = hijack.call
		
		Thread.new do
			socket.write("Hello World")
			socket.close
		end
		
		return nil # ???
	end
end
```

- The socket might not actually be a raw socket, if the server is using TLS.
- Extreme care is required in order to handle the protocol correctly.
- It's not clear if such a design can work with anything other than HTTP/1.
- The user code **must** return from the `call(env)` method in order for the server continue handling requests.
- It's not clear what the response should be.

## Typical Scenarios

There are several typical scenarios where `rack.hijack` has been used.

### ActionCable

ActionCable uses full hijack in order to negotiate and communicate using WebSocket protocol. Such a design requires the ActionCable server to run in the same process as the web server.

### MessageBus

MessageBus uses full hijack in order to keep the socket alive and feed messages occasionally.

## Supporting HTTP/2

It is possible to support partial hijack in HTTP/2. The hijacked stream is multiplexed the same as any other connection. However, such a design cannot be thread safe without significant design trade-offs.
