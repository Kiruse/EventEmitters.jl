@doc """`EventEmitter` is an object-oriented event dispatcher. The design of the `Event` struct is
borrows from established industry patterns. While it is possible to call the various methods
contained in this module directly, it is intended to be used like this:

```julia
using EventEmitters # default exports

@eventemitter struct MyStruct
  @event create
  @event close
  @event something
end

function do_something(inst::MyStruct)
  @dispatch inst.create
  # do something
  for i in 1:10
    @dispatch inst.something count = i
    # do something
  end
end

function Base.close(inst::MyStruct)
  @dispatch inst.close
  # close
end

inst = MyStruct()

@on inst.create begin
  println("created")
end

@on inst.close begin
  println("closed")
end

@once inst.something begin
  println("something")
end

do_something(inst)
close(inst)
```
""" EventEmitter
