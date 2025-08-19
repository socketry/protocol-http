# Protocol::HTTP

Provides abstractions for working with the HTTP protocol.

[![Development Status](https://github.com/socketry/protocol-http/workflows/Test/badge.svg)](https://github.com/socketry/protocol-http/actions?workflow=Test)

## Features

  - General abstractions for HTTP requests and responses.
  - Symmetrical interfaces for client and server.
  - Light-weight middleware model for building applications.

## Usage

Please see the [project documentation](https://socketry.github.io/protocol-http/) for more details.

  - [Getting Started](https://socketry.github.io/protocol-http/guides/getting-started/index) - This guide explains how to use `protocol-http` for building abstract HTTP interfaces.

  - [Message Body](https://socketry.github.io/protocol-http/guides/message-body/index) - This guide explains how to work with HTTP request and response message bodies using `Protocol::HTTP::Body` classes.

  - [Middleware](https://socketry.github.io/protocol-http/guides/middleware/index) - This guide explains how to build and use HTTP middleware with `Protocol::HTTP::Middleware`.

  - [Hypertext References](https://socketry.github.io/protocol-http/guides/hypertext-references/index) - This guide explains how to use `Protocol::HTTP::Reference` for constructing and manipulating hypertext references (URLs with parameters).

  - [URL Parsing](https://socketry.github.io/protocol-http/guides/url-parsing/index) - This guide explains how to use `Protocol::HTTP::URL` for parsing and manipulating URL components, particularly query strings and parameters.

  - [Streaming](https://socketry.github.io/protocol-http/guides/streaming/index) - This guide gives an overview of how to implement streaming requests and responses.

  - [Design Overview](https://socketry.github.io/protocol-http/guides/design-overview/index) - This guide explains the high level design of `protocol-http` in the context of wider design patterns that can be used to implement HTTP clients and servers.

## Releases

Please see the [project releases](https://socketry.github.io/protocol-http/releases/index) for all releases.

### v0.52.0

  - Add `Protocol::HTTP::Headers#to_a` method that returns the fields array, providing compatibility with standard Ruby array conversion pattern.
  - Expose `tail` in `Headers.new` so that trailers can be accurately reproduced.
  - Add agent context.

### v0.51.0

  - `Protocol::HTTP::Headers` now raise a `DuplicateHeaderError` when a duplicate singleton header (e.g. `content-length`) is added.
  - `Protocol::HTTP::Headers#add` now coerces the value to a string when adding a header, ensuring consistent behaviour.
  - `Protocol::HTTP::Body::Head.for` now accepts an optional `length` parameter, allowing it to create a head body even when the body is not provided, based on the known content length.

### v0.50.0

    - Drop support for Ruby v3.1.

### v0.48.0

  - Add support for parsing `accept`, `accept-charset`, `accept-encoding` and `accept-language` headers into structured values.

### v0.46.0

  - Add support for `priority:` header.

### v0.33.0

  - Clarify behaviour of streaming bodies and copy `Protocol::Rack::Body::Streaming` to `Protocol::HTTP::Body::Streamable`.
  - Copy `Async::HTTP::Body::Writable` to `Protocol::HTTP::Body::Writable`.

### v0.31.0

  - Ensure chunks are flushed if required, when streaming.

### v0.30.0

  - [`Request[]` and `Response[]` Keyword Arguments](https://socketry.github.io/protocol-http/releases/index#request[]-and-response[]-keyword-arguments)
  - [Interim Response Handling](https://socketry.github.io/protocol-http/releases/index#interim-response-handling)

## See Also

  - [protocol-http1](https://github.com/socketry/protocol-http1) — HTTP/1 client/server implementation using this
    interface.
  - [protocol-http2](https://github.com/socketry/protocol-http2) — HTTP/2 client/server implementation using this
    interface.
  - [async-http](https://github.com/socketry/async-http) — Asynchronous HTTP client and server, supporting multiple HTTP
    protocols & TLS.
  - [async-websocket](https://github.com/socketry/async-websocket) — Asynchronous client and server WebSockets.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
