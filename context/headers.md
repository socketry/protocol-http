# Headers

This guide explains how to work with HTTP headers using `protocol-http`.

## Core Concepts

`protocol-http` provides several core concepts for working with HTTP headers:

- A {ruby Protocol::HTTP::Headers} class which represents a collection of HTTP headers with built-in security and policy features.
- Header-specific classes like {ruby Protocol::HTTP::Header::Accept} and {ruby Protocol::HTTP::Header::Authorization} which provide specialized parsing and formatting.
- Trailer security validation to prevent HTTP request smuggling attacks.

## Usage

The {Protocol::HTTP::Headers} class provides a comprehensive interface for creating and manipulating HTTP headers:

```ruby
require "protocol/http"

headers = Protocol::HTTP::Headers.new
headers.add("content-type", "text/html")
headers.add("set-cookie", "session=abc123")

# Access headers
content_type = headers["content-type"] # => "text/html"

# Check if header exists
headers.include?("content-type") # => true
```

### Header Policies

Different header types have different behaviors for merging, validation, and trailer handling:

```ruby
# Some headers can be specified multiple times
headers.add("set-cookie", "first=value1")
headers.add("set-cookie", "second=value2")

# Others are singletons and will raise errors if duplicated
headers.add("content-length", "100")
# headers.add('content-length', '200') # Would raise DuplicateHeaderError
```

### Structured Headers

Some headers have specialized classes for parsing and formatting:

```ruby
# Accept header with media ranges
accept = Protocol::HTTP::Header::Accept.new("text/html,application/json;q=0.9")
media_ranges = accept.media_ranges

# Authorization header
auth = Protocol::HTTP::Header::Authorization.basic("username", "password")
# => "Basic dXNlcm5hbWU6cGFzc3dvcmQ="
```

### Trailer Security

HTTP trailers are headers that appear after the message body. For security reasons, only certain headers are allowed in trailers:

```ruby
# Working with trailers
headers = Protocol::HTTP::Headers.new([
	["content-type", "text/html"],
	["content-length", "1000"]
])

# Start trailer section
headers.trailer!

# These will be allowed (safe metadata)
headers.add("etag", '"12345"')
headers.add("date", Time.now.httpdate)

# Each of these will raise InvalidTrailerError for security:
headers.add("authorization", "Bearer token") # => raises InvalidTrailerError (credential leakage risk)
headers.add("connection", "close") # => raises InvalidTrailerError (hop-by-hop header)
headers["content-length"] = "0" # => raises InvalidTrailerError (framing header)
```

The trailer security system prevents HTTP request smuggling by restricting which headers can appear in trailers. Once `trailer!` has been called, every method which appends fields (`add`, `set`, `[]=` and `merge!`) validates the header against the policy before modifying the headers, and raises {ruby Protocol::HTTP::InvalidTrailerError} if it is not permitted:

**Allowed headers** (return `true` for `trailer?`):
- `date` - Response generation timestamps.
- `digest` - Content integrity verification.
- `etag` - Cache validation tags.
- `server-timing` - Performance metrics.

**Forbidden headers** (return `false` for `trailer?`):
- `authorization` - Prevents credential leakage.
- `connection`, `te`, `transfer-encoding` - Hop-by-hop headers that control connection behavior.
- `cookie`, `set-cookie` - State information needed during initial processing.
- `accept` - Content negotiation must occur before response generation.
