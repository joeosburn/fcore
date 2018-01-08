require_relative 'core'

core = Core.new
core.add_tcp_server(ip_address: '127.0.0.1', port: 2000)
core.run
