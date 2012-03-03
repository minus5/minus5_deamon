module Minus5
  module Service

    module ZmqHelper
      
      def zmq_init
        @zmq_proxy = ZmqProxy.new(options.sockets, self) if options.sockets
      end

      def publish(socket, action, data=nil)
        @zmq_proxy.send_msg(socket, action, data)
      end

      def cast(socket_name, action, data=nil)
        @zmq_proxy.send_msg socket_name, action, data
      end

      def zmq_receive(socket, action, data)
        @receive_proc.call socket, action.to_sym, data
      end

      def zmq_request(socket, action, data)
        @receive_proc.call socket, action.to_sym, data
      end
      
    end
    
    class ZmqProxy

      require 'em-zeromq'

      def initialize(sockets, handler)
        @sockets = sockets
        @handler = handler
        connect 
      end
      
      def send_msg(socket_name, action, data=nil)
        s = @sockets[socket_name]
        raise "socket #{socket_name} not found" unless s
        msg = ZmqProxy.pack({action => data})
        s.socket.send_msg msg
      end

      def self.unpack(msg)
        JSON.parse(Zlib::Inflate.inflate(msg))    
      end

      def self.pack(actions)
        Zlib::Deflate.deflate(JSON.generate(actions))
      end

      private
      
      def connect
        @context = EM::ZeroMQ::Context.new(1)
        @sockets.each_pair do |name, socket|
          socket.name = name
          socket.type_id = ZMQ.const_get(socket.type.upcase)
          # if EventMachine::ZeroMQ::Context::READABLES.include?(type)
          #   connect_readable(socket, type)
          # elsif EventMachine::ZeroMQ::Context::WRITABLES.include?(type)
          #   connect_writable(socket, type)
          # end
          socket.socket = self.send("connect_#{socket.type}", socket)
        end
      end

      def connect_pub(socket)
        controller = BaseController.new(@handler, socket.name)
        @context.socket(ZMQ::PUB, controller){|s| s.bind socket.address}
      end

      def connect_sub(socket)
        controller = ReceiveController.new(@handler, socket.name)
        @context.socket(ZMQ::SUB, controller) do |s|
          s.subscribe(socket.filter || '')
          s.connect socket.address
        end
      end

      # def connect_req(socket)
      #   controller = RequestResponseController.new(@handler, socket.name)
      #   @context.socket(ZMQ::XREQ, controller) do |s| 
      #     s.connect socket.address
      #   end
      # end

      # def connect_rep(socket)
      #   controller = RequestResponseController.new(@handler, socket.name)
      #   @context.socket(ZMQ::XREP, controller) do |s| 
      #     s.bind socket.address 
      #   end
      # end

      def connect_router(socket)
        controller = RequestResponseController.new(@handler, socket.name)
        @context.socket(ZMQ::ROUTER, controller) do |s| 
          s.bind socket.address
        end
      end

      def connect_dealer(socket)
        controller = ReceiveController.new(@handler, socket.name)
        @context.socket(ZMQ::DEALER, controller) do |s| 
          s.connect socket.address 
        end
      end

    end

    class BaseController

      attr_reader :received

      def initialize(handler, name)
        @handler = handler
        @name = name
      end

      def on_writable(socket)
        print "on_writable\n"
      end

      def on_readable(socket, parts)
        message = parts.map{|p| p.copy_out_string}.join("")
        handle_message(socket, message)
      end

      protected
      
      def handle_message(socket, message)
        print "unhandled message\n"
      end

    end

    class RequestResponseController < BaseController

      def on_readable(socket, parts)
        from = parts[0].copy_out_string
        message = parts[1].copy_out_string
        response = {}
        ZmqProxy.unpack(message).each_pair do |action, data|
          response[action] = @handler.zmq_request(@name, action, data)
        end      
        socket.send_msg from, ZmqProxy.pack(response)
      end

    end

    class ReceiveController < BaseController

      def on_readable(socket, parts)
        message = parts[0].copy_out_string
        ZmqProxy.unpack(message).each_pair do |action, data|
          @handler.zmq_receive @name, action, data
        end        
      end
      
    end

  end
end
