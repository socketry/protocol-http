# Releases

## v0.46.0

  - Add support for `priority:` header.

## v0.33.0

  - Clarify behaviour of streaming bodies and copy `Protocol::Rack::Body::Streaming` to `Protocol::HTTP::Body::Streamable`.
  - Copy `Async::HTTP::Body::Writable` to `Protocol::HTTP::Body::Writable`.

## v0.31.0

  - Ensure chunks are flushed if required, when streaming.

## v0.30.0

### `Request[]` and `Response[]` Keyword Arguments

The `Request[]` and `Response[]` methods now support keyword arguments as a convenient way to set various positional arguments.

``` ruby
# Request keyword arguments:
client.get("/", headers: {"accept" => "text/html"}, authority: "example.com")

# Response keyword arguments:
def call(request)
	return Response[200, headers: {"content-Type" => "text/html"}, body: "Hello, World!"]
```

### Interim Response Handling

The `Request` class now exposes a `#interim_response` attribute which can be used to handle interim responses both on the client side and server side.

On the client side, you can pass a callback using the `interim_response` keyword argument which will be invoked whenever an interim response is received:

``` ruby
client = ...
response = client.get("/index", interim_response: proc{|status, headers| ...})
```

On the server side, you can send an interim response using the `#send_interim_response` method:

``` ruby
def call(request)
	if request.headers["expect"] == "100-continue"
		# Send an interim response:
		request.send_interim_response(100)
	end
	
	# ...
end
```
