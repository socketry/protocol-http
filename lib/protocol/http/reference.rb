# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

require_relative 'url'

module Protocol
	module HTTP
		# A relative reference, excluding any authority. The path part of an HTTP request.
		class Reference
			include Comparable
			
			# Generate a reference from a path and user parameters. The path may contain a `#fragment` or `?query=parameters`.
			def self.parse(path = '/', parameters = nil)
				base, fragment = path.split('#', 2)
				path, query = base.split('?', 2)
				
				self.new(path, query, fragment, parameters)
			end
			
			def initialize(path = '/', query = nil, fragment = nil, parameters = nil)
				@path = path
				@query = query
				@fragment = fragment
				@parameters = parameters
			end
			
			# The path component, e.g. /foo/bar/index.html
			attr_accessor :path
			
			# The un-parsed query string, e.g. 'x=10&y=20'
			attr_accessor :query
			
			# A fragment, the part after the '#'
			attr_accessor :fragment
			
			# User supplied parameters that will be appended to the query part.
			attr_accessor :parameters
			
			def freeze
				return self if frozen?
				
				@path.freeze
				@query.freeze
				@fragment.freeze
				@parameters.freeze
				
				super
			end
			
			def to_ary
				[@path, @query, @fragment, @parameters]
			end
			
			def <=> other
				to_ary <=> other.to_ary
			end
			
			def self.[] reference
				if reference.is_a? self
					return reference
				else
					return self.parse(reference)
				end
			end
			
			def parameters?
				@parameters and !@parameters.empty?
			end
			
			def query?
				@query and !@query.empty?
			end
			
			def fragment?
				@fragment and !@fragment.empty?
			end
			
			def append(buffer)
				if query?
					buffer << URL.escape_path(@path) << '?' << @query
					buffer << '&' << URL.encode(@parameters) if parameters?
				else
					buffer << URL.escape_path(@path)
					buffer << '?' << URL.encode(@parameters) if parameters?
				end
				
				if fragment?
					buffer << '#' << URL.escape(@fragment)
				end
				
				return buffer
			end
			
			def to_s
				append(String.new)
			end
			
			# Merges two references as specified by RFC2396, similar to `URI.join`.
			def + other
				other = self.class[other]
				
				self.class.new(
					expand_path(self.path, other.path, true),
					other.query,
					other.fragment,
					other.parameters,
				)
			end
			
			# Just the base path, without any query string, parameters or fragment.
			def base
				self.class.new(@path, nil, nil, nil)
			end
			
			# Update the reference with the given path, parameters and fragment.
			# @argument path [String] Append the string to this reference similar to `File.join`.
			# @argument parameters [Hash] Append the parameters to this reference.
			# @argument fragment [String] Set the fragment to this value.
			# @argument pop [Boolean] If the path contains a trailing filename, pop the last component of the path before appending the new path.
			# @argument merge [Boolean] If the parameters are specified, merge them with the existing parameters.
			def with(path: nil, parameters: nil, fragment: @fragment, pop: false, merge: true)
				if @parameters
					if parameters and merge
						parameters = @parameters.merge(parameters)
					else
						parameters = @parameters
					end
				end
				
				if @query and !merge
					query = nil
				else
					query = @query
				end
				
				if path
					path = expand_path(@path, path, pop)
				else
					path = @path
				end
				
				self.class.new(path, query, fragment, parameters)
			end
			
			private
			
			def split(path)
				if path.empty?
					[path]
				else
					path.split('/', -1)
				end
			end
			
			def expand_absolute_path(path, parts)
				parts.each do |part|
					if part == '..'
						path.pop
					elsif part == '.'
						# Do nothing.
					else
						path << part
					end
				end
				
				if path.first != ''
					path.unshift('')
				end
			end
			
			def expand_relative_path(path, parts)
				parts.each do |part|
					if part == '..' and path.any?
						path.pop
					elsif part == '.'
						# Do nothing.
					else
						path << part
					end
				end
			end
			
			# @param pop [Boolean] whether to remove the last path component of the base path, to conform to URI merging behaviour, as defined by RFC2396.
			def expand_path(base, relative, pop = true)
				if relative.start_with? '/'
					return relative
				end
				
				path = split(base)
				
				# RFC2396 Section 5.2:
				# 6) a) All but the last segment of the base URI's path component is
				# copied to the buffer.  In other words, any characters after the
				# last (right-most) slash character, if any, are excluded.
				path.pop if pop or path.last == ''
				
				parts = split(relative)
				
				# Absolute path:
				if path.first == ''
					expand_absolute_path(path, parts)
				else
					expand_relative_path(path, parts)
				end	
				
				return path.join('/')
			end
		end
	end
end
