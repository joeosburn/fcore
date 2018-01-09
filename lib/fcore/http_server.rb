require 'http-parser-lite'

class FCore::HttpServer
  # HTTP Request Class
  class Request
    attr_reader :env

    def initialize(env)
      @env = env
    end
  end

   # HTTP Response Class
   class Response
    STATUS_CODES = {
      100 => '100 Continue',
      101 => '101 Switching Protocols',
      200 => '200 OK',
      201 => '201 Created',
      202 => '202 Accepted',
      203 => '203 Non-Authoritative Information',
      204 => '204 No Content',
      205 => '205 Reset Content',
      206 => '206 Partial Content',
      300 => '300 Multiple Choices',
      301 => '301 Moved Permanently',
      302 => '302 Found',
      303 => '303 See Other',
      304 => '304 Not Modified',
      305 => '305 Use Proxy',
      307 => '307 Temporary Redirect',
      400 => '400 Bad Request',
      401 => '401 Unauthorized',
      402 => '402 Payment Required',
      403 => '403 Forbidden',
      404 => '404 Not Found',
      405 => '405 Method Not Allowed',
      406 => '406 Not Acceptable',
      407 => '407 Proxy Authentication Required',
      408 => '408 Request Timeout',
      409 => '409 Conflict',
      410 => '410 Gone',
      411 => '411 Length Required',
      412 => '412 Precondition Failed',
      413 => '413 Request Entity Too Large',
      414 => '414 Request-URI Too Long',
      415 => '415 Unsupported Media Type',
      416 => '416 Requested Range Not Satisfiable',
      417 => '417 Expectation Failed',
      500 => '500 Internal Server Error',
      501 => '501 Not Implemented',
      502 => '502 Bad Gateway',
      503 => '503 Service Unavailable',
      504 => '504 Gateway Timeout',
      505 => '505 HTTP Version Not Supported'
    }.freeze

    attr_accessor :status
    attr_reader :content, :headers, :env

    def initialize(env)
      @env = env
      @content = ''
      @headers = {}
    end

    def content=(value)
      @content = value.to_s
    end

    def headers=(value)
      @headers = value.to_h
    end

    def flush
      headers['Content-Length'] ||= content.bytesize
      send("HTTP/1.1 #{STATUS_CODES[status] || '200 OK'}\r\n")
      send(headers.map { |key, value| formatted_header(key, value) }.join)
      send("\r\n")
      send(content)

      handler.flush_and_close
    end

    private

    def send(data)
      handler.write_data(data)
    end

    def handler
      env['HANDLER']
    end

    def formatted_header(key, value)
      if value.is_a?(Array)
        value.map { |subvalue| formatted_header(key, subvalue) }.join
      else
        "#{key}: #{value}\r\n"
      end
    end
  end

  class Handler
    attr_accessor :outgoing, :server
  
    def initialize(server)
      @outgoing = ''
      @server = server
      @close = false
    end
  
    def outgoing?
      outgoing.size > 0
    end

    def close?
      @close
    end

    def flush_and_close
      @close = true
    end
  
    def write_data(data)
      @outgoing += data
    end

    def read_data(data)
      http_parser << data
    rescue HTTP::Parser::Error
      send_error('400 Bad Request')
    end

    def env
      @env ||= {'HANDLER' => self}
    end

    def send_error(status_code)
      write_data "HTTP/1.1 #{status_code}\r\nContent-Type: text/plain\r\nConnection: close\r\n"
      flush_and_close
    end

    VALID_METHODS = %w(GET POST PUT DELETE PATCH HEAD OPTIONS).freeze
    MAPPED_HEADERS = { 'cookie' => 'HTTP_COOKIE', 'if-none-match' => 'HTTP_IF_NONE_MATCH',
                       'content-type' => 'HTTP_CONTENT_TYPE', 'content-length' => 'HTTP_CONTENT_LENGTH' }.freeze

    def http_parser
      @parser ||= HTTP::Parser.new.tap do |parser|
        parser.on_message_begin do
          env['HTTP_COOKIE'] = ''
          env['HTTP_POST_CONTENT'] = ''
          env['HTTP_PROTOCOL'] = 'http'
          env['HTTP_PATH_INFO'] = ''
          env['HTTP_QUERY_STRING'] = ''
          env['HTTP_HEADERS'] ||= Hash.new
        end

        parser.on_message_complete do
          raise HTTP::Parser::Error, 'Missing request method' unless env['HTTP_REQUEST_METHOD']
          server.handle_request(env)
        end

        parser.on_url do |url|
          raise HTTP::Parser::Error, 'Invalid request method' unless VALID_METHODS.include?(parser.http_method)

          env['HTTP_REQUEST_METHOD'] = parser.http_method
          env['HTTP_REQUEST_URI'] = url

          matches = url.match(/^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/)
          if matches
            env['HTTP_PROTOCOL'] = matches[2]
            env['HTTP_PATH_INFO'] = matches[5]
            env['HTTP_QUERY_STRING'] = matches[7]
          end
        end

        parser.on_header_field { |name| @current_header = name }

        parser.on_header_value do |value|
          if key = MAPPED_HEADERS[@current_header.downcase]
            env[key] = value
          else
            env['HTTP_HEADERS'][@current_header] = value
          end
        end

        parser.on_headers_complete { @current_header = nil }

        parser.on_body { |body| env['HTTP_POST_CONTENT'] = body }
      end
    end
  end

  def initialize(ip_address = 'localhost', &block)
    @ip_address = ip_address
    @request_handler = block
  end

  def listen(port)
    FCore.add_server(TCPServer.new(@ip_address, port), ->(server) do
      begin
        FCore.add_handler(server.accept_nonblock, Handler.new(self))
      rescue IO::WaitReadable, Errno::EINTR
      end
    end)

    FCore.run
  end

  def handle_request(env)
    @request_handler.call(Request.new(env), Response.new(env))
  end
end
