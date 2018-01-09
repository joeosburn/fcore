require 'socket'

class FCore::Core
  def initialize
    @servers = {}
    @handlers = {}
  end

  def add_server(io, proc)
    @servers[io] = proc
  end

  def remove_server(io)
    @servers.delete(io)
  end

  def add_handler(io, handler)
    @handlers[io] = handler
  end

  def remove_handler(io)
    @handlers.delete(io)
  end

  def run
    loop do
      rs, ws = IO.select(@servers.keys + @handlers.keys, @handlers.select { |k, v| v.outgoing? }.keys)
    
      rs.each do |read|
        if @servers[read]
          @servers[read].call(read)
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
end
