# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

require_relative "url"

module Protocol
	module HTTP
		# A relative reference, excluding any authority. The path part of an HTTP request.
		class Reference
			include Comparable
			
			# Generate a reference from a path and user parameters. The path may contain a `#fragment` or `?query=parameters`.
			def self.parse(path = "/", parameters = nil)
				base, fragment = path.split("#", 2)
				path, query = base.split("?", 2)
				
				self.new(path, query, fragment, parameters)
			end
			
			# Initialize the reference.
			#
			# @parameter path [String] The path component, e.g. `/foo/bar/index.html`.
			# @parameter query [String | Nil] The un-parsed query string, e.g. 'x=10&y=20'.
			# @parameter fragment [String | Nil] The fragment, the part after the '#'.
			# @parameter parameters [Hash | Nil] User supplied parameters that will be appended to the query part.
			def initialize(path = "/", query = nil, fragment = nil, parameters = nil)
				@path = path
				@query = query
				@fragment = fragment
				@parameters = parameters
			end
			
			# @attribute [String] The path component, e.g. `/foo/bar/index.html`.
			attr_accessor :path
			
			# @attribute [String] The un-parsed query string, e.g. 'x=10&y=20'.
			attr_accessor :query
			
			# @attribute [String] The fragment, the part after the '#'.
			attr_accessor :fragment
			
			# @attribute [Hash] User supplied parameters that will be appended to the query part.
			attr_accessor :parameters
			
			# Freeze the reference.
			#
			#	@returns [Reference] The frozen reference.
			def freeze
				return self if frozen?
				
				@path.freeze
				@query.freeze
				@fragment.freeze
				@parameters.freeze
				
				super
			end
			
			# Implicit conversion to an array.
			#
			# @returns [Array] The reference as an array, `[path, query, fragment, parameters]`.
			def to_ary
				[@path, @query, @fragment, @parameters]
			end
			
			# Compare two references.
			#
			# @parameter other [Reference] The other reference to compare.
			# @returns [Integer] -1, 0, 1 if the reference is less than, equal to, or greater than the other reference.
			def <=> other
				to_ary <=> other.to_ary
			end
			
			# Type-cast a reference.
			#
			# @parameter reference [Reference | String] The reference to type-cast.
			# @returns [Reference] The type-casted reference.
			def self.[] reference
				if reference.is_a? self
					return reference
				else
					return self.parse(reference)
				end
			end
			
			# @returns [Boolean] Whether the reference has parameters.
			def parameters?
				@parameters and !@parameters.empty?
			end
			
			# @returns [Boolean] Whether the reference has a query string.
			def query?
				@query and !@query.empty?
			end
			
			# @returns [Boolean] Whether the reference has a fragment.
			def fragment?
				@fragment and !@fragment.empty?
			end
			
			# Append the reference to the given buffer.
			def append(buffer = String.new)
				if query?
					buffer << URL.escape_path(@path) << "?" << @query
					buffer << "&" << URL.encode(@parameters) if parameters?
				else
					buffer << URL.escape_path(@path)
					buffer << "?" << URL.encode(@parameters) if parameters?
				end
				
				if fragment?
					buffer << "#" << URL.escape(@fragment)
				end
				
				return buffer
			end
			
			# Convert the reference to a string, e.g. `/foo/bar/index.html?x=10&y=20#section`
			#
			# @returns [String] The reference as a string.
			def to_s
				append
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
			#
			# @parameter path [String] Append the string to this reference similar to `File.join`.
			# @parameter parameters [Hash] Append the parameters to this reference.
			# @parameter fragment [String] Set the fragment to this value.
			# @parameter pop [Boolean] If the path contains a trailing filename, pop the last component of the path before appending the new path.
			# @parameter merge [Boolean] If the parameters are specified, merge them with the existing parameters, otherwise replace them (including query string).
			def with(path: nil, parameters: false, fragment: @fragment, pop: false, merge: true)
				if merge
					# Merge mode: combine new parameters with existing, keep query:
					# parameters = (@parameters || {}).merge(parameters || {})
					if @parameters
						if parameters
							parameters = @parameters.merge(parameters)
						else
							parameters = @parameters
						end
					elsif !parameters
						parameters = @parameters
					end
					
					query = @query
				else
					# Replace mode: use new parameters if provided, clear query when replacing:
					if parameters == false
						# No new parameters provided, keep existing:
						parameters = @parameters
						query = @query
					else
						# New parameters provided, replace and clear query:
						# parameters = parameters
						query = nil
					end
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
					path.split("/", -1)
				end
			end
			
			def expand_absolute_path(path, parts)
				parts.each do |part|
					if part == ".."
						path.pop
					elsif part == "."
						# Do nothing.
					else
						path << part
					end
				end
				
				if path.first != ""
					path.unshift("")
				end
			end
			
			def expand_relative_path(path, parts)
				parts.each do |part|
					if part == ".." and path.any?
						path.pop
					elsif part == "."
						# Do nothing.
					else
						path << part
					end
				end
			end
			
			# @param pop [Boolean] whether to remove the last path component of the base path, to conform to URI merging behaviour, as defined by RFC2396.
			def expand_path(base, relative, pop = true)
				if relative.start_with? "/"
					return relative
				end
				
				path = split(base)
				
				# RFC2396 Section 5.2:
				# 6) a) All but the last segment of the base URI's path component is
				# copied to the buffer.  In other words, any characters after the
				# last (right-most) slash character, if any, are excluded.
				path.pop if pop or path.last == ""
				
				parts = split(relative)
				
				# Absolute path:
				if path.first == ""
					expand_absolute_path(path, parts)
				else
					expand_relative_path(path, parts)
				end	
				
				return path.join("/")
			end
		end
	end
end
