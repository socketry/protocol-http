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

  - [Headers](https://socketry.github.io/protocol-http/guides/headers/index) - This guide explains how to work with HTTP headers using `protocol-http`.

  - [Middleware](https://socketry.github.io/protocol-http/guides/middleware/index) - This guide explains how to build and use HTTP middleware with `Protocol::HTTP::Middleware`.

  - [Streaming](https://socketry.github.io/protocol-http/guides/streaming/index) - This guide gives an overview of how to implement streaming requests and responses.

  - [Design Overview](https://socketry.github.io/protocol-http/guides/design-overview/index) - This guide explains the high level design of `protocol-http` in the context of wider design patterns that can be used to implement HTTP clients and servers.

## Releases

Please see the [project releases](https://socketry.github.io/protocol-http/releases/index) for all releases.

### v0.71.0

  - Parse all cookie pairs from `Cookie` header fields, including multiple semicolon-separated pairs within each field.
  - Preserve `Set-Cookie` parsing as one cookie plus attributes/directives per header field.

### v0.70.0

  - Add stable preference ordering for weighted `Accept`, `Accept-Charset`, `Accept-Encoding`, `Accept-Language`, and `TE` values.

### v0.69.0

  - Add `Protocol::HTTP::Body::Readable#to_io` for obtaining an IO-compatible stream adapter.
  - Avoid creating an implicit buffered output for `Protocol::HTTP::Body::Stream`.

### v0.68.0

  - Add HTTP status descriptions.

### v0.67.0

  - Parse and resolve HTTP `Range` header values according to the default headers policy.
  - Classify malformed header values as bad requests.

### v0.66.0

  - Introduce `Protocol::HTTP::RemoteError` for remote endpoint failures where application processing may have occurred.

### v0.65.0

  - Improve `Accept` header parsing for quoted pairs, malformed parameters, invalid wildcards, and invalid quality factors.
  - Emit multiple `Set-Cookie` values as separate header fields and delimit combined `Cookie` values with a space after each semicolon.

### v0.64.0

  - Add `Protocol::HTTP::Request#rewind!` and `#retry!` for preparing requests to be sent again.

### v0.63.0

  - Add support for the HTTP `QUERY` method.

### v0.62.1

  - Fix handling of `Stream#read(0)`, it must return a mutable string (or clear the given buffer).

### v0.61.0

  - Introduce `Protocol::HTTP::RefusedError` for indicating a stream or request was refused before processing and can be safely retried. `RequestRefusedError` is provided as an alias for backwards compatibility.

## See Also

  - [protocol-http1](https://github.com/socketry/protocol-http1) — HTTP/1 client/server implementation using this
    interface.
  - [protocol-http2](https://github.com/socketry/protocol-http2) — HTTP/2 client/server implementation using this
    interface.
  - [protocol-url](https://github.com/socketry/protocol-url) — URL parsing and manipulation library.
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
