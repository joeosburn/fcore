require 'socket'

class Handler
  attr_reader :socket

  def initialize(socket)
    @socket = socket
  end

  def read
    data, _ = @socket.recvfrom(1024)
    data
  end
end
