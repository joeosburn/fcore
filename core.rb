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
      rs, _ = IO.select(@servers + @handlers.keys)
    
      rs.each do |read|
        if read.is_a?(TCPServer)
          handle_incoming(read)
        else
          data = read.read_nonblock(1024)
          @handlers[read].read_data(data)
        end
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
