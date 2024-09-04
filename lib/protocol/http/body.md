# Protocol::HTTP::Body

Bodies represent readable input streams. Some bodies are also writable.

In general, you read chunks of data from a body until it is empty and returns `nil`. Upon reading `nil`, the body is considered consumed and should not be read from again.

Reading can also fail, for example if the body represents a streaming upload, and the connection is lost. In this case, the body will raise some kind of error.

If you don't want to read from a stream, and instead want to close it immediately, you can call `close` on the body.
