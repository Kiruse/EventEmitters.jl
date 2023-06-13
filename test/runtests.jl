using Test
using EventEmitters
using EventEmitters: dispatch, eventnames

@eventemitter struct Foo
  @event bar
  @event baz
  @event boink
end

@testset "EventEmitters" begin
  @testset "1 Listener" begin
    emitter = EventEmitter(:test)
    called = false
    
    emitter() do event
      called = true
    end
    dispatch(emitter)
    
    @test called
  end
  
  @testset "2 Listeners" begin
    emitter = EventEmitter(:test)
    called1 = called2 = false
    
    emitter() do _
      called1 = true
    end
    emitter() do _
      called2 = true
    end
    dispatch(emitter)
    
    @test called1 && called2
  end
  
  @testset "Subsequent events" begin
    emitter = EventEmitter(:test)
    calls = 0
    
    emitter() do _
      calls += 1
    end
    dispatch(emitter)
    dispatch(emitter)
    
    @test calls == 2
  end
  
  @testset "Once listener" begin
    emitter = EventEmitter(:test)
    calls = 0
    
    emitter.once() do _
      calls += 1
    end
    dispatch(emitter)
    dispatch(emitter)
    
    @test calls == 1
  end
  
  @testset "Macros" begin
    let foo = Foo()
      @test Set(eventnames(foo)) == Set((:bar, :baz, :boink))
      
      called_bar = false
      @on foo.bar() do event
        @test event.name == :bar
        called_bar = true
      end
      
      called_baz = nothing
      @on foo.baz() do event
        @test event.name == :baz
        called_baz = event.args[:count]
      end
      
      called_boink = 0
      @once foo.boink() do event
        @test event.name == :boink
        called_boink += 1
      end
      
      @dispatch foo.bar
      @dispatch foo.baz count=42
      @dispatch foo.boink
      @dispatch foo.boink
      @test called_bar && called_baz == 42 && called_boink == 1
    end
  end
end
