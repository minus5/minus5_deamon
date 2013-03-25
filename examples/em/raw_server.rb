require 'rubygems'
require 'em-zeromq'

zmq = EM::ZeroMQ::Context.new(1)

# DEALER - ROUTER
EM.run {
  push = zmq.socket(ZMQ::DEALER)
  push.bind("ipc:///tmp/zmq_server_rr.socket") #  tcp://127.0.0.1:2091

  push.on(:message) do |m|
  	push.send_msg("DEALER RE: #{m}")
  end

  EM.add_periodic_timer(1) {
    puts "PUB"
    push.send_msg("DEALER SEND: Hello")
  }
}

# PUB - SUB
# EM.run {
#   push = zmq.socket(ZMQ::PUB)
#   push.connect("ipc:///tmp/zmq_server_pub.socket") #  tcp://127.0.0.1:2091

#   EM.add_periodic_timer(1) {
#     puts "PUB"
#     push.send_msg("Hello")
#   }
# }