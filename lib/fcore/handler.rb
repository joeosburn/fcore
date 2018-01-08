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
