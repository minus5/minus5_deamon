require 'rubygems'
require 'em-zeromq'

zmq = EM::ZeroMQ::Context.new(1)

# DEALER - ROUTER
EM.run {
  push = zmq.socket(ZMQ::ROUTER)
  push.bind("ipc:///tmp/zmq_server_rr.socket") #  tcp://127.0.0.1:2091

  push.on(:message) do |*m|
    puts "message size: #{m.size}"
    from = m[0].copy_out_string
    msg = m[1].copy_out_string
    puts "received: #{msg}"
    push.send_msg(from, "re: #{msg}")
  end

#  EM.add_periodic_timer(1) {
#    puts "PUB"
#    push.send_msg("DEALER SEND: Hello")
#  }
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
