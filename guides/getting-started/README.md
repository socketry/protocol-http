# Getting Started

This guide explains how to use `protocol-http` for building abstract HTTP interfaces.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add protocol-http
~~~

## Core Concepts

`protocol-http` has several core concepts:

- A {ruby Protocol::HTTP::Request} instance which represents an abstract HTTP request. Specific versions of HTTP may subclass this to track additional state.
- A {ruby Protocol::HTTP::Response} instance which represents an abstract HTTP response. Specific versions of HTTP may subclass this to track additional state.
- A {ruby Protocol::HTTP::Middleware} interface for building HTTP applications.
- A {ruby Protocol::HTTP::Headers} interface for storing HTTP headers with semantics based on documented specifications (RFCs, etc).
- A set of {ruby Protocol::HTTP::Body} classes which handle the internal request and response bodies, including bi-directional streaming.

## Integration

This gem does not provide any specific client or server implementation, rather it's used by several other gems.

- [Protocol::HTTP1] & [Protocol::HTTP2] which provide client and server implementations.
- [Async::HTTP] which provides connection pooling and concurrency.

## Usage

### Headers

{ruby Protocol::HTTP::Headers} provides semantically meaningful interpretation of header values implements case-normalising keys.

``` ruby
require 'protocol/http/headers'

headers = Protocol::HTTP::Headers.new

headers['Content-Type'] = "image/jpeg"

headers['content-type']
# => "image/jpeg"
```

### Reference

{ruby Protocol::HTTP::Reference} is used to construct "hypertext references" which consist of a path and URL-encoded key/value pairs.

``` ruby
require 'protocol/http/reference'

reference = Protocol::HTTP::Reference.new("/search", q: 'kittens')

reference.to_s
# => "/search?q=kittens"
```

### URL

{ruby Protocol::HTTP::URL} is used to parse incoming URLs to extract the query string and other relevant details.

``` ruby
require 'protocol/http/url'

reference = Protocol::HTTP::Reference.parse("/search?q=kittens")

parameters = Protocol::HTTP::URL.decode(reference.query_string)
# => {"q"=>"kittens"}
```

This implemenation may be merged with {ruby Protocol::HTTP::Reference} or removed in the future.
