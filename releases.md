# Releases

## Unreleased

  - Improve consistency of Body `#inspect`.
  - Improve `as_json` support for Body wrappers.

## v0.52.0

  - Add `Protocol::HTTP::Headers#to_a` method that returns the fields array, providing compatibility with standard Ruby array conversion pattern.
  - Expose `tail` in `Headers.new` so that trailers can be accurately reproduced.
  - Add agent context.

## v0.51.0

  - `Protocol::HTTP::Headers` now raise a `DuplicateHeaderError` when a duplicate singleton header (e.g. `content-length`) is added.
  - `Protocol::HTTP::Headers#add` now coerces the value to a string when adding a header, ensuring consistent behaviour.
  - `Protocol::HTTP::Body::Head.for` now accepts an optional `length` parameter, allowing it to create a head body even when the body is not provided, based on the known content length.

## v0.50.0

    - Drop support for Ruby v3.1.

## v0.48.0

  - Add support for parsing `accept`, `accept-charset`, `accept-encoding` and `accept-language` headers into structured values.

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
