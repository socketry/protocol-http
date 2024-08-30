# Releases

## Unreleased

### `Request[]` and `Response[]` Keyword Arguments

The `Request[]` and `Response[]` methods now support keyword arguments as a convenient way to set various positional arguments.

```ruby
# Request keyword arguments:
client.get("/", headers: {"accept" => "text/html"}, authority: "example.com")

# Response keyword arguments:
def call(request)
	return Response[200, headers: {"content-Type" => "text/html"}, body: "Hello, World!"]
end
```
