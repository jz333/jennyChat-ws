# ##############################################
# # Using faye-websocket
# ##############################################

require 'faye/websocket'
require 'rack'

class MyServer

  def initialize(socket_port, socket_host)
    @socket_port = socket_port
    @socket_host = socket_host

    @clients = []
    @wsServer = wsServer
    start_server
  end

  def wsServer
    wsServer = lambda do |env|
    # inspect env to see if the incoming request is a WebSocket request
      if Faye::WebSocket.websocket?(env)
        # It is a WebSocket connection
        ws = Faye::WebSocket.new(env)


        # open gets invoked when a new connection to the server happens
        # store a newly connected client in the @clients array
        ws.on :open do |event|
          puts "Connection open with ws #{ws.object_id}."
          ws.send("Welcome to the chat room! Start chatting!")
          @clients << ws

          puts "In the chat room: "
          @clients.each {|client| puts client}
        end


        # message gets invoked when a WebSocket message is received
        # by the server. The event object passed in has a 'data' attribute
        # which is the message being sent
        ws.on :message do |event|
          puts "Client: #{event.data}"

          # broadcase to clients
          @clients.each { |client|
            if client != ws
                client.send("#{ws}: #{event.data}")
            end
          }

        end


        # close gets invoked when the client closes the connection
        # remove the client from client list when disconnected
        ws.on :close do |event|
          puts "Closing the connection with #{ws}..."
          puts "close, #{ws.object_id}, #{event.code}, #{event.reason}"

          @clients.delete(ws)
          @clients.each { |client| client.send("#{ws} has left.")}
          ws = nil
        end


        # Return async Rack response
        # this line is essential!
        ws.rack_response
      else
        # Normal HTTP request
        [200, { 'Content-Type' => 'text/plain' }, ['Hello, this is a normal HTTP Request.']]
      end
    end

  end


  def start_server
    # run the server on thin
    # load adapter to be able to upgrade handshake to websocket protocol
    Faye::WebSocket.load_adapter('thin')

    # use thin.run(wsServer,...) to run the lambda and get env
    thin = Rack::Handler.get('thin')
    thin.run(@wsServer, :Host => @socket_host, :Port => @socket_port) do |server|
      #You can set options on the server here, for example to set up SSL:
      # if secure
      #   server.ssl_options = {
      #     :private_key_file => 'path/to/ssl.key',
      #     :cert_chain_file  => 'path/to/ssl.crt'
      #   }
      #   server.ssl = true
    end

  end

end



MyServer.new(4567, 'localhost')


