require 'rubygems'
require 'em-zeromq'
require 'pp'

class EMTestRouterHandler
  attr_reader :received
  def initialize
    @received = []
  end
  def on_writable(socket)
  end
  def on_readable(socket, messages)
    messages.each do |m|
      print "client received: #{m.copy_out_string}\n"
    end    
  end
end

class Handler
  attr_reader :received

  def initialize(name, respond)
    @name = name
    @respond = respond
  end

  def on_writable(socket)

  end

  def on_readable(socket, parts)
    if parts.size == 2
      from = parts[0].copy_out_string
      message = parts[1].copy_out_string
    else
      message = parts[0].copy_out_string
    end
    print "#{@name} received: #{message}\n"
    socket.send_msg(from, "re:#{message}") if @respond
  end
end

trap('INT') do
  EM::stop()
end

ctx = EM::ZeroMQ::Context.new(1)
EM.run do

  addr = "ipc:///tmp/aaa"
  #server = ctx.socket(ZMQ::DEALER, dealer_hndlr)
  server = ctx.socket(ZMQ::ROUTER, Handler.new("server", true))
  #server.identity = "server"
  server.bind(addr)
  
  #client = ctx.socket(ZMQ::ROUTER, router_hndlr)
  client = ctx.socket(ZMQ::DEALER, Handler.new("client", false))
  #client.identity = "client"
  client.connect(addr)
  
  EM::add_periodic_timer(0.5) do
    client.send_msg("pero")
    #router_conn.send_msg("pero")
  end
  
end
