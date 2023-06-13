module EventEmitters

struct Ident{T} end

#region EventEmitter
export EventEmitter
struct EventEmitter
  name::Symbol
  _listeners::Set
end
EventEmitter(name::Symbol) = EventEmitter(name, Set())
EventEmitter(name) = EventEmitter(Symbol(string(name)))

Base.getproperty(e::EventEmitter, name::Symbol) = getproperty(e, Ident{name}())
Base.getproperty(e::EventEmitter, ::Ident{:once}) = listener -> register(OnceListener(listener), e)
Base.getproperty(e::EventEmitter, ::Ident{S}) where S = getfield(e, S)

(e::EventEmitter)(listener) = register(listener, e)
#endregion EventEmitter

#region CancelFlag
mutable struct CancelFlag
  value::Bool
end
(flag::CancelFlag)() = flag.value = true
Base.getindex(flag::CancelFlag) = flag.value
#endregion CancelFlag

#region Event
export Event
struct Event
  emitter::EventEmitter
  args::Dict{Symbol}
  result::Ref
  cancel::CancelFlag
end
Event(emitter, args = ()) = Event(emitter, Dict{Symbol, Any}(args), Ref{Any}(), CancelFlag(false))

Base.getproperty(e::Event, name::Symbol) = getproperty(e, Ident{name}())
Base.getproperty(e::Event, ::Ident{:name}) = e.emitter.name
Base.getproperty(e::Event, ::Ident{S}) where S = getfield(e, S)
Base.propertynames(::Event) = (fieldnames(Event)..., :name)
#endregion Event

#region Specialized Listeners
"""A wrapper for a listener which automatically unregisters itself after being called once."""
struct OnceListener
  listener
end
Base.isequal(lhs::OnceListener, rhs::OnceListener) = lhs.listener === rhs.listener

function (listener::OnceListener)(e::Event)
  unregister(listener, e.emitter)
  listener.listener(e)
end
#endregion Specialized Listeners

#region Methods
function register(listener, e::EventEmitter)
  push!(e._listeners, listener)
  () -> unregister(listener, e)
end

function unregister(listener, e::EventEmitter)
  delete!(e._listeners, listener)
  nothing
end

"""`dispatch(e::EventEmitter; kwargs...)` dispatches an `Event` corresponding to `e` to all
listeners. `kwargs` is passed to the `Event` constructor.
"""
function dispatch(e::EventEmitter; kwargs...)
  event = Event(e, kwargs)
  for listener in e._listeners
    listener(event)
  end
  nothing
end

export eventnames
"""`eventnames(e)` retrieves a list of all event names for `e`. For an `EventEmitter`, it simply
returns `(e.name,)`. The fallback assumes the use of the `@eventemitter` macro, which defines and
populiates an `_events` dictionary, from which the event names are retrieved.
"""
eventnames(e::EventEmitter) = (e.name,)
# assumes use of @eventemitter macro, which defines a `Dict` named `_events`
eventnames(e) = keys(e._events)
#endregion Methods

include("./EventEmitters.docs.jl")
include("./macros.jl")

end # module EventEmitters
