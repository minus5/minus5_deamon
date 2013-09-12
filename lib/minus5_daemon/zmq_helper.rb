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
        if action.to_s == "ponuda"
          action = "get"
        end
        headers[:action]   = action    if headers[:action].nil?
        headers[:encoding] = "deflate" if headers[:encoding].nil?

        unless body.nil?
          if body.kind_of?(String)
            headers[:content_type] = "string" unless headers[:content_type]
          elsif body.kind_of?(Array) || body.kind_of?(Hash)
            headers[:content_type] = "json"
          else
            headers[:content_type] = "json/packed"
            body = {:body => body}
          end
          body        = JSON.generate(body) unless body.kind_of?(String)
          msg_body    = if headers[:encoding] == "deflate"
                          Zlib::Deflate.deflate(body)
                        elsif headers[:encoding] == "gzip"
                          gzip(body)
                        else
                          body
                        end
        end
        msg_headers = JSON.generate(headers).gsub("\n", "")
        [msg_headers, msg_body]
      end

      def self.gzip(string)
        wio = StringIO.new("w")
        w_gz = Zlib::GzipWriter.new(wio)
        w_gz.write(string)
        w_gz.close
        wio.string
      end

      def self.unpack_msg(msg_parts)
        if msg_parts.size == 1
          msg = msg_parts[0].copy_out_string
          if msg.start_with?("igraci;") || msg.start_with?("listici;") ||
              msg.start_with?("transakcije;")
            action, headers, body = self.unpack_mongo_replication_message(msg)
          else
            action, headers, body = self.unpack_ponuda_service_message(msg)
          end
        else
          msg_headers = msg_parts[-2].copy_out_string
          msg_body    = msg_parts[-1].copy_out_string
          headers     = Hashie::Mash.new(JSON.parse(msg_headers))

          body        = Zlib::Inflate.inflate(msg_body)
          body        = JSON.parse(body) if headers.content_type.include?("json")
          body        = body["body"] if headers.content_type.include?("packed")
          action      = headers.action
          if action == "get"
            action = "ponuda"
            headers.action = action
            headers.message_type = "insert/delete"
            headers.version = body["version"]
          end
        end
        msg_parts.each{|part| part.close}
        [action, headers, body]
      end

      private

      def self.unpack_mongo_replication_message(msg)
        parts = msg.split("\n")
        body = parts[1]
        header_parts = parts[0].split(";")
        headers = Hashie::Mash.new({})
        action = header_parts[0]
        %w(msg_type igrac_id doc_id action message_no).each_with_index do |key, idx|
          headers[key] = header_parts[idx]
        end
        [action, headers, body]
      end

      def self.unpack_ponuda_service_message(msg)
        data = JSON.parse(Zlib::Inflate.inflate(msg))
        action = data.keys[0]
        body = data[action]
        headers  = Hashie::Mash.new({})
        if action == "version"
          headers.version = body
          body = nil
        end
        if action == "get"
          headers.message_type = "insert/delete"
          headers.version = body["version"]
        end
        action = "ponuda"
        [action, headers, body]
      end

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
        conn = @context.socket(ZMQ::PUB)
        conn.bind(socket.address)
        conn
      end

      def connect_sub(socket)
        conn = @context.socket(ZMQ::SUB)
        conn.connect(socket.address)
        conn.subscribe(socket.filter || '')
        conn.on(:message){ |*parts|
          on_receive(conn, parts, socket.name)
        }
        conn
      end

      def connect_router(socket)
        conn = @context.socket(ZMQ::ROUTER)
        conn.bind(socket.address)
        conn.on(:message) { |*parts|
          on_request_response(conn, parts, socket.name)
        }
        conn
      end

      def connect_dealer(socket)
        conn = @context.socket(ZMQ::DEALER)
        conn.connect(socket.address)
        conn.on(:message) { |*parts|
          on_receive(conn, parts, socket.name)
        }
        conn
      end

      def on_receive(conn, parts, socket)
        action, headers, body = ZmqProxy.unpack_msg(parts)
        @handler.zmq_receive socket, action, headers, body
      end

      def on_request_response(conn, parts, socket)
        puts "on_request_response"
        from = parts[0].copy_out_string
        action, headers, body = ZmqProxy.unpack_msg(parts)
        @handler.zmq_request(socket, action, headers, body) do |response_body, response_headers|
          puts "sending response: #{response_body}"
          conn.send_msg *([from] + ZmqProxy.pack_msg(action, response_headers, response_body))
        end
      end

    end
  end
end
