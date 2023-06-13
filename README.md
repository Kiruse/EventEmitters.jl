# EventEmitters.jl
`EventEmitter` is an object-oriented event dispatcher with a set of macros.

There are generally two ways to work with `EventEmitter`s:

## Standalone Event Emitter
You can create a new `EventEmitter(:name)` and operate on this instance. It does not need to be contained within another object. As a Functor, you call it to register a listener, and call the returned value to unregister that same listener. The pattern then looks like so:

```julia
using EventEmitters

emitter = EventEmitter(:foo)

emitter() do event
  println(event.name) # foo (Symbol)
  println(event.args) # Dict(bar => 42, baz => 69)
  println(event.result) # nothing
  
  println(event.cancel[]) # false
  event.cancel()
  println(event.cancel[]) # true
end

EventEmitters.dispatch(emitter; bar = 42, baz = 69)
```

Currently, *EventEmitters* only supports a dictionary of arguments. I may add vector arguments as well should the demand arise.

Further, you can call `emitter.once() do event #= ... =# end` instead to register a one-time event listener.

## Contained Event Emitter
You may integrate a `struct` you define with *EventEmitters* through the `@eventemitter` macro. You then call the various other analogous macros to register listeners and dispatch events:

```julia
using EventEmitters

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

@on inst.create() do event
  println("created")
end

@on inst.close() do event
  println("closed")
end

@once inst.something() do event
  println("something")
end

do_something(inst)
close(inst)
```

Under the hood, `@eventemitter` creates a new field `_events::Dict{Symbol, EventEmitter}`, as well as a constructor taking in all fields *but* the `_events` field, and automatically populates that field for you, including corresponding `EventEmitter`s. In future, I may implement this using a more optimized data structure such as a named tuple.

The `@on` macro is analog to calling the `EventEmitter` functor. In fact, internally, it simply re-routes the first argument, which is expected to be a `obj.event` expression, and calls the corresponding `EventEmitter`.

The `@dispatch` macro then corresponds to the `EventEmitters.dispatch` method. While you cannot pass keyword arguments to macro calls, the macro simulates keyword arguments by accepting an arbitrary number of assignment expressions like in `do_something` above.

The `@event` macro is virtual, i.e. it does not actually exist. It is only valid in the context of `@eventemitter` where it is used to mark event names and then removed before evaluation.

## Notes
- **Note 1:** All event listeners are collected in a set, thus you cannot register the same listener more than once. `once` listeners are equal to other `once` listeners wrapping the same listener, but not to the unwrapped listener.
- **Note 2:** `EventEmitters.dispatch` is not exported by default as I consider the term `dispatch` to be too generic and thus to likely clash with other libraries.
- **Note 3:** Currently, `@event name` does not take any more arguments. If you have a clever idea to get more use out of it, hmu.

## License
Licensed under MIT. Copyright © Kiruse 2023.
