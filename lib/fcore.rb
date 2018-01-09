class FCore
  class << self
    extend Forwardable

    def instance
      @instance ||= Core.new
    end

    def_delegators :instance, :add_server, :remove_server, :add_handler, :remove_handler, :run
  end
end

require 'fcore/core'
require 'fcore/http_server'
