
# TODO: replace Dict for efficiency. it's just easier this way for now...
export @eventemitter
macro eventemitter(defn::Expr)
  @assert defn.head == :struct "Expected `struct` keyword"
  
  # ismutable = defn.args[1]::Bool
  name = defn.args[2]::Symbol
  
  # inject `EventEmitter` mapping into fields
  block = defn.args[3]
  @assert block.head == :block
  
  fields = filter(block.args) do arg
    return arg isa Symbol ||
      arg isa Expr && arg.head == :(::)
  end
  fields = map!(fields, fields) do arg
    if arg isa Expr
      arg.args[1]
    else
      arg
    end
  end
  
  # collect events & remove @event macrocalls
  events = Symbol[]
  iseventmacro = expr -> expr isa Expr && expr.head == :macrocall && expr.args[1] == Symbol("@event")
  while (idx = findfirst(iseventmacro, block.args)) !== nothing
    expr = block.args[idx]::Expr
    line = if idx > 0 && block.args[idx-1] isa LineNumberNode
      block.args[idx-1]
    end
    
    idxs = if line === nothing; (idx-1, idx) else (idx,) end
    deleteat!(block.args, idxs)
    push!(events, expr.args[3]::Symbol)
  end
  
  # only do stuff when we actually have events defined
  if isempty(events)
    return defn
  end
  
  push!(block.args, :(_events::Dict{Symbol, EventEmitter}))
  quote
    $defn
    $(Expr(
      :function,
      Expr(:call, esc(name), fields...),
      Expr(:block,
        Expr(:(=), :inst, Expr(:call, esc(name), fields..., :(Dict{Symbol, EventEmitter}()))),
        map(events) do event
          Expr(
            :(=),
            Expr(:ref,
              Expr(:(.), :inst, QuoteNode(:_events)),
              QuoteNode(event),
            ),
            Expr(:call, :EventEmitter, QuoteNode(event)),
          )
        end...,
        :inst,
      ),
    ))
  end
end

export @on
macro on(listener::Expr)
  @assert listener.head == :do "Expected `do` keyword"
  
  call, lambda = listener.args
  @assert call.head == :call
  @assert lambda.head == :(->)
  
  ident = eventident(call.args[1])
  Expr(:do, :($(ident)()), esc(lambda))
end

export @once
macro once(listener::Expr)
  @assert listener.head == :do "Expected `do` keyword"
  
  call, lambda = listener.args
  @assert call.head == :call
  @assert lambda.head == :(->)
  
  ident = eventident(call.args[1])
  Expr(:do, :($(ident).once()), esc(lambda))
end

export @dispatch
macro dispatch(expr::Expr, args...)
  ident = eventident(expr)
  
  params = Expr(:parameters)
  for arg in args
    if arg isa Symbol
      push!(params.args, Expr(:kw, arg, esc(arg)))
    elseif arg isa Expr
      @assert arg.head == :(=) "Expected assignment expression for keyword argument to `@dispatch`"
      @assert arg.args[1] isa Symbol "`@dispatch` keyword name must be a symbol"
      value = if arg.args[2] isa Symbol
        esc(arg.args[2])
      else
        arg.args[2]
      end
      push!(params.args, Expr(:kw, arg.args[1], value))
    else
      error("Expected symbol or expression as keyword argument to `@dispatch`")
    end
  end
  
  Expr(
    :call,
    :dispatch,
    params,
    ident,
  )
end

function eventident(expr::Expr)
  @assert expr.head == :(.)
  obj = esc(expr.args[1]::Symbol)
  evt = expr.args[2]::QuoteNode
  :($(obj)._events[$evt])
end
