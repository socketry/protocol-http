# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative '../error'

module HTTP
	module Protocol
		module HTTP1
			class Connection
				CRLF = "\r\n".freeze
				HTTP10 = "HTTP/1.0".freeze
				HTTP11 = "HTTP/1.1".freeze
				
				def initialize(stream, persistent = true)
					@stream = stream
					
					@persistent = persistent
					
					@count = 0
				end
				
				attr :stream
				
				# Whether the connection is persistent.
				attr :persistent
				
				# The number of requests processed.
				attr :count
				
				def persistent?(version, headers)
					if version == HTTP10
						if connection = headers[CONNECTION]
							return connection.include?(KEEP_ALIVE)
						else
							return false
						end
					else
						if connection = headers[CONNECTION]
							return !connection.include?(CLOSE)
						else
							return true
						end
					end
				end
				
				# Write the appropriate header for connection persistence.
				def write_persistent_header(version)
					if version == HTTP10
						@stream.write("connection: keep-alive\r\n") if @persistent
					else
						@stream.write("connection: close\r\n") unless @persistent
					end
				end
				
				# Effectively close the connection and return the underlying IO.
				# @return [IO] the underlying non-blocking IO.
				def hijack
					@persistent = false
					
					@stream.flush
					
					return @stream
				end
				
				# Close the connection and underlying stream.
				def close
					@stream.close
				end
				
				def write_request(authority, method, path, version, headers)
					@stream.write("#{method} #{path} #{version}\r\n")
					@stream.write("host: #{authority}\r\n")
					
					write_headers(headers)
					write_persistent_header(version)
					
					@stream.flush
				end
				
				def write_response(version, status, headers, body = nil, head = false)
					@stream.write("#{version} #{status}\r\n")
					
					write_headers(headers)
					write_persistent_header(version)
					write_body(body, version == HTTP11, head)
				end
				
				def write_headers(headers)
					headers.each do |name, value|
						@stream.write("#{name}: #{value}\r\n")
					end
				end
				
				def each_line
					while line = read_line
						yield line
					end
				end
				
				def read_line
					# To support Ruby 2.3, we do the following which is pretty inefficient. Ruby 2.4+ can do the following:
					# @stream.gets(CRLF, chomp: true) or raise EOFError
					if line = @stream.gets(CRLF)
						return line.chomp!(CRLF)
					else
						raise EOFError
					end
				end
				
				def read_request
					method, path, version = read_line.split(/\s+/, 3)
					headers = read_headers
					
					@persistent = persistent?(version, headers)
					
					body = read_request_body(headers)
					
					@count += 1
					
					return headers.delete(HOST), method, path, version, headers, body
				end
				
				def read_response(method)
					version, status, reason = read_line.split(/\s+/, 3)
					
					status = Integer(status)
					
					headers = read_headers
					
					@persistent = persistent?(version, headers)
					
					body = read_response_body(method, status, headers)
					
					@count += 1
					
					return version, status, reason, headers, body
				end
				
				def read_headers
					fields = []
					
					self.each_line do |line|
						if line =~ /^([a-zA-Z\-\d]+):\s*(.+?)\s*$/
							fields << [$1, $2]
						else
							break
						end
					end
					
					return Headers.new(fields)
				end
				
				def read_chunk
					length = self.read_line.to_i(16)
					
					if length == 0
						self.read_line
						
						return nil
					end
					
					# Read the data:
					chunk = @stream.read(length)
					
					# Consume the trailing CRLF:
					crlf = @stream.read(2)
					
					return chunk
				end
				
				def write_chunk(chunk)
					if chunk.nil?
						@stream.write("0\r\n\r\n")
					elsif !chunk.empty?
						@stream.write("#{chunk.bytesize.to_s(16).upcase}\r\n")
						@stream.write(chunk)
						@stream.write(CRLF)
						@stream.flush
					end
				end
				
				def write_empty_body(body)
					@stream.write("content-length: 0\r\n\r\n")
				end
				
				def write_fixed_length_body(body, length, head)
					@stream.write("content-length: #{length}\r\n\r\n")
					return if head
					
					chunk_length = 0
					body.each do |chunk|
						chunk_length += chunk.bytesize
						
						if chunk_length > length
							raise ArgumentError, "Trying to write #{chunk_length} bytes, but content length was #{length} bytes!"
						end
						
						@stream.write(chunk)
					end
					
					@stream.flush
					
					if chunk_length != length
						raise ArgumentError, "Wrote #{chunk_length} bytes, but content length was #{length} bytes!"
					end
				end
				
				def write_chunked_body(body, head)
					@stream.write("transfer-encoding: chunked\r\n\r\n")
					return if head
					
					body.each do |chunk|
						next if chunk.size == 0
						
						@stream.write("#{chunk.bytesize.to_s(16).upcase}\r\n")
						@stream.write(chunk)
						@stream.write(CRLF)
						@stream.flush
					end
					
					@stream.write("0\r\n\r\n")
				end
				
				def write_body_and_close(body, head)
					# We can't be persistent because we don't know the data length:
					@persistent = false
					@stream.write("\r\n")
					
					unless head
						body.each do |chunk|
							@stream.write(chunk)
							@stream.flush
						end
					end
					
					@stream.stream.close_write
				end
				
				def write_body(body, chunked = true, head = false)
					if body.nil? or body.empty?
						write_empty_body(body)
					elsif length = body.length
						write_fixed_length_body(body, length, head)
					elsif chunked
						write_chunked_body(body, head)
					else
						write_body_and_close(body, head)
					end
					
					@stream.flush
				end
				
				def read_chunked_body
					buffer = String.new.b
					
					while chunk = read_chunk
						buffer << chunk
						chunk.clear
					end
					
					return buffer
				end
				
				def read_fixed_body(length)
					@stream.read(length)
				end
				
				def read_tunnel_body
					read_remainder_body
				end
				
				def read_remainder_body
					@stream.read
				end
				
				HEAD = "HEAD".freeze
				CONNECT = "CONNECT".freeze
				
				def read_response_body(method, status, headers)
					# RFC 7230 3.3.3
					# 1.  Any response to a HEAD request and any response with a 1xx
					# (Informational), 204 (No Content), or 304 (Not Modified) status
					# code is always terminated by the first empty line after the
					# header fields, regardless of the header fields present in the
					# message, and thus cannot contain a message body.
					if method == "HEAD" or (status >= 100 and status < 200) or status == 204 or status == 304
						return nil
					end
					
					# 2.  Any 2xx (Successful) response to a CONNECT request implies that
					# the connection will become a tunnel immediately after the empty
					# line that concludes the header fields.  A client MUST ignore any
					# Content-Length or Transfer-Encoding header fields received in
					# such a message.
					if method == "CONNECT" and status == 200
						return read_tunnel_body
					end
					
					return read_body(headers, true)
				end
				
				def read_request_body(headers)
					# 6.  If this is a request message and none of the above are true, then
					# the message body length is zero (no message body is present).
					return read_body(headers)
				end
				
				def read_body(headers, remainder = false)
					# 3.  If a Transfer-Encoding header field is present and the chunked
					# transfer coding (Section 4.1) is the final encoding, the message
					# body length is determined by reading and decoding the chunked
					# data until the transfer coding indicates the data is complete.
					if transfer_encoding = headers.delete(TRANSFER_ENCODING)
						# If a message is received with both a Transfer-Encoding and a
						# Content-Length header field, the Transfer-Encoding overrides the
						# Content-Length.  Such a message might indicate an attempt to
						# perform request smuggling (Section 9.5) or response splitting
						# (Section 9.4) and ought to be handled as an error.  A sender MUST
						# remove the received Content-Length field prior to forwarding such
						# a message downstream.
						if headers[CONTENT_LENGTH]
							raise BadRequest, "Message contains both transfer encoding and content length!"
						end
						
						if transfer_encoding.last == CHUNKED
							return read_chunked_body
						else
							# If a Transfer-Encoding header field is present in a response and
							# the chunked transfer coding is not the final encoding, the
							# message body length is determined by reading the connection until
							# it is closed by the server.  If a Transfer-Encoding header field
							# is present in a request and the chunked transfer coding is not
							# the final encoding, the message body length cannot be determined
							# reliably; the server MUST respond with the 400 (Bad Request)
							# status code and then close the connection.
							return read_body_remainder
						end
					end

					# 5.  If a valid Content-Length header field is present without
					# Transfer-Encoding, its decimal value defines the expected message
					# body length in octets.  If the sender closes the connection or
					# the recipient times out before the indicated number of octets are
					# received, the recipient MUST consider the message to be
					# incomplete and close the connection.
					if content_length = headers.delete(CONTENT_LENGTH)
						length = Integer(content_length)
						if length > 0
							return read_fixed_body(length)
						elsif length == 0
							return nil
						else
							raise BadRequest, "Invalid content length: #{content_length}"
						end
					end
					
					if remainder
						# 7.  Otherwise, this is a response message without a declared message
						# body length, so the message body length is determined by the
						# number of octets received prior to the server closing the
						# connection.
						return read_remainder_body
					end
				end
			end
		end
	end
end
