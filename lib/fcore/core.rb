require 'socket'

module FCore
  class Core
    def initialize
      @servers = []
      @handlers = {}
    end

    def add_tcp_server(port:, ip_address: 'localhost')
      @servers << TCPServer.new(ip_address, port)
    end

    def run
      loop do
        rs, ws = IO.select(@servers + @handlers.keys, @handlers.select { |k, v| v.outgoing? }.keys)
      
        rs.each do |read|
          if read.is_a?(TCPServer)
            handle_incoming(read)
          else
            begin
              data = read.read_nonblock(1024)
              @handlers[read].read_data(data)
            rescue EOFError
              @handlers.delete(read)
            end
          end
        end

        ws.each do |write|
          sent = write.send(@handlers[write].outgoing, 0)
          @handlers[write].outgoing.slice!(0..(sent - 1))
        end
      end
    end

    def handle_incoming(server)
      begin
        socket = server.accept_nonblock
        @handlers[socket] = Handler.new
      rescue IO::WaitReadable, Errno::EINTR
        IO.select([server])
        retry
      end
    end
  end
end
