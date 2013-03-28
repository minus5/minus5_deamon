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

      def zmq_request(socket, action, headers, body, &callback)
        @receive_proc.call(socket, action.to_sym, body, headers, callback)
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
          #ako je vec postavljen content_type prihvati taj
          headers[:content_type] = "string" unless headers[:content_type]
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
        if msg_parts.size == 1
          # fall back na stari nacin
          # ovako salje ponuda_service
          data = JSON.parse(Zlib::Inflate.inflate(msg_parts[0].copy_out_string))
          key = data.keys[0]
          msg_parts.each{|part| part.close}
          [key, {}, data[key]]
        else
          msg_headers = msg_parts[-2].copy_out_string
          msg_body    = msg_parts[-1].copy_out_string
          headers     = Hashie::Mash.new(JSON.parse(msg_headers))

          body        = Zlib::Inflate.inflate(msg_body)
          body        = JSON.parse(body) if headers.content_type.include?("json")
          body        = body["body"] if headers.content_type.include?("packed")
          action      = headers.action
          msg_parts.each{|part| part.close}
          [action, headers, body]
        end
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
        conn = @context.socket(ZMQ::PUB)
        conn.bind(socket.address)
        conn
      end

      def connect_sub(socket)
        controller = ReceiveController.new(@handler, socket.name)
        conn = @context.socket(ZMQ::SUB)
        conn.connect(socket.address)
        conn.subscribe(socket.filter || '')
        conn.on(:message){ |*parts|
          controller.on_readable(conn, parts)
        }
        conn
      end

      def connect_router(socket)
        controller = RequestResponseController.new(@handler, socket.name)
        conn = @context.socket(ZMQ::ROUTER)
        conn.bind(socket.address)
        conn.on(:message) { |*parts|
          controller.on_readable(conn, parts)
        }
        conn
      end

      def connect_dealer(socket)
        controller = ReceiveController.new(@handler, socket.name)
        conn = @context.socket(ZMQ::DEALER)
        conn.connect(socket.address)
        conn.on(:message) { |*parts|
          controller.on_readable(conn, parts)
        }
        conn
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
        @handler.zmq_request(@name, action, headers, body) do |response_body, response_headers|
          socket.send_msg *([from] + ZmqProxy.pack_msg(action, response_headers, response_body))
        end
      end

    end

    class ReceiveController < BaseController
    end

  end
end
