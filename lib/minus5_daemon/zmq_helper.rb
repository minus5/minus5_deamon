require 'json'
require 'zlib'
require 'hashie'

module Minus5
  module Service

    module ZmqHelper
      
      def zmq_init
        @zmq_proxy = ZmqProxy.new(options.sockets, self) if options.sockets
      end

      def publish(socket, action, body = nil, headers = {})
        @zmq_proxy.send_msg socket, action, body, headers
      end

      def cast(socket, action, body = nil, headers={})
        @zmq_proxy.send_msg socket, action, body, headers
      end

      def zmq_receive(socket, action, headers, body)
        @receive_proc.call socket, action.to_sym, body, headers
      end

      def zmq_request(socket, action, headers, body)
        @receive_proc.call socket, action.to_sym, body, headers
      end
      
    end
    
    class ZmqProxy

      require 'em-zeromq'

      def initialize(sockets, handler)
        @sockets = sockets
        @handler = handler
        connect 
      end

      #creates multipart message, with two parts headers and body
      #action is part of the header
      #body is compressed
      def send_msg(socket_name, action, body = nil, headers = {})
        find_socket(socket_name).socket.send_msg(*ZmqProxy.pack_msg(action, headers, body))
      end      
      
      def self.pack_msg(action, headers, body)
        headers = {} unless headers
        headers[:action]       = action
        headers[:encoding]     = "deflate"
        if body.kind_of?(String)
          headers[:content_type] = "string"
        elsif body.kind_of?(Array) || body.kind_of?(Hash)
          headers[:content_type] = "json"
        else
          headers[:content_type] = "json/packed"
          body = {:body => body} 
        end
        body        = JSON.generate(body) unless body.kind_of?(String)
        msg_headers = JSON.generate(headers)
        msg_body    = Zlib::Deflate.deflate(body)
        [msg_headers, msg_body]
      end

      def self.unpack_msg(msg_parts)
        msg_headers = msg_parts[-2].copy_out_string
        msg_body    = msg_parts[-1].copy_out_string
        headers     = Hashie::Mash.new(JSON.parse(msg_headers))
        body        = Zlib::Inflate.inflate(msg_body) 
        body        = JSON.parse(body) if headers.content_type.include?("json")
        body        = body["body"] if headers.content_type.include?("packed")
        action      = headers.action
        [action, headers, body]
      end

      private

      def find_socket(socket_name)
        s = @sockets[socket_name]
        raise "socket #{socket_name} not found" unless s
        s
      end
      
      def connect
        @context = EM::ZeroMQ::Context.new(1)
        @sockets.each_pair do |name, socket|
          socket.name = name
          socket.type_id = ZMQ.const_get(socket.type.upcase)
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
      end

      def on_readable(socket, parts)
        action, headers, body = ZmqProxy.unpack_msg(parts)
        @handler.zmq_receive @name, action, headers, body
      end

    end

    class RequestResponseController < BaseController

      def on_readable(socket, parts)
        from = parts[0].copy_out_string
        action, headers, body = ZmqProxy.unpack_msg(parts)
        response_body, response_headers = @handler.zmq_request(@name, action, headers, body)
        socket.send_msg *([from] + ZmqProxy.pack_msg(action, response_headers, response_body))
      end

    end

    class ReceiveController < BaseController
    end

  end
end
