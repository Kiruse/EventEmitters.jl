#!/usr/bin/env julia

contents = ""
open("../README.md") do f
  global contents
  contents = read(f, String)
end

open("EventEmitters.docs.jl", "w") do f
  write(f, "@doc \"\"\"")
  write(f, contents)
  write(f, "\n\"\"\" EventEmitters\n")
end
