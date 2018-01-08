require 'socket'

require './handler'

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
      set, _ = IO.select(@servers + @handlers.keys)
    
      set.each do |read|
        if read.is_a?(TCPServer)
          handle_incoming(read)
        else
          puts "Got #{@handlers[read].read}"
        end
      end
    end
  end

  def handle_incoming(server)
    begin
      socket = server.accept_nonblock
      @handlers[socket] = Handler.new(socket, @handler_class)
    rescue IO::WaitReadable, Errno::EINTR
      IO.select([server])
      retry
    end
  end
end
