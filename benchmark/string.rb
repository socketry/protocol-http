# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.

def generator
	100000.times do |i|
		yield "foo #{i}"
	end
end

def consumer_without_clear
	buffer = String.new
	generator do |chunk|
		buffer << chunk
	end
	return nil
end

def consumer_with_clear
	buffer = String.new
	generator do |chunk|
		buffer << chunk
		chunk.clear
	end
	return nil
end

require "benchmark"

Benchmark.bm do |x|
	x.report("consumer_with_clear") do
		consumer_with_clear
		GC.start
		
	end
	
	x.report("consumer_without_clear") do
		consumer_without_clear
		GC.start
	end
end
