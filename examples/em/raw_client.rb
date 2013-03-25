require 'rubygems'
require 'em-zeromq'

zmq = EM::ZeroMQ::Context.new(1)

# DEALER - ROUTER
EM.run {
  pull = zmq.socket(ZMQ::ROUTER)
  pull.connect("ipc:///tmp/zmq_server_rr.socket")   # tcp://127.0.0.1:2091

  pull.on(:message) { |m|
  	puts "ROUTER: #{m.copy_out_string}"
  }
}


# PUB - SUB
# EM.run {
#   pull = zmq.socket(ZMQ::SUB)
#   resultBind = pull.bind("ipc:///tmp/zmq_server_pub.socket")   # tcp://127.0.0.1:2091
#   puts "RESULT BIND: #{resultBind}"
#   resultSubscribe = pull.subscribe('')
#   puts "RESULT SUBSCRIBE: #{resultSubscribe}"

#   pull.on(:message) { |part|
#   	print "SUB "
#     puts part.copy_out_string
#     part.close
#   }
# }
