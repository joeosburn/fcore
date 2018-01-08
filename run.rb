require_relative 'core'

core = Core.new
core.add_tcp_server(ip_address: '127.0.0.1', port: 2000)
core.run

# reads = [server]

# loop do
#   rs, ws, = IO.select(reads)

#   rs.each do |read|
#     puts rs.inspect
#     if read == server
#       begin # emulate blocking accept
#         sock = serv.accept_nonblock
#       rescue IO::WaitReadable, Errno::EINTR
#         IO.select([serv])
#         retry
#       end
#     end
#   end
# end
