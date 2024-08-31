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

  - [Design Overview](https://socketry.github.io/protocol-http/guides/design-overview/index) - This guide explains the high level design of `protocol-http` in the context of wider design patterns that can be used to implement HTTP clients and servers.

## Releases

Please see the [project releases](https://socketry.github.io/protocol-http/releases/index) for all releases.

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
