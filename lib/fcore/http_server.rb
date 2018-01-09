class FCore::HttpServer
  class Handler
    attr_accessor :outgoing
  
    def initialize
      @outgoing = ''
    end
  
    def outgoing?
      outgoing.size > 0
    end
  
    def write_data(data)
      @outgoing += data
    end
  
    def read_data(data)
      write_data data
      puts "Got #{data}"
    end
  end

  def initialize(ip_address = 'localhost')
    @ip_address = ip_address
  end

  def listen(port)
    FCore.add_server(TCPServer.new(@ip_address, port), ->(server) do
      begin
        FCore.add_handler(server.accept_nonblock, Handler.new)
      rescue IO::WaitReadable, Errno::EINTR
      end
    end)

    FCore.run
  end
end
