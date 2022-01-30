### jennyChat-ws
Barebone chat program using WebSocket. Testable in CLI.

This project uses [faye-websocket](https://github.com/faye/faye-websocket-ruby) gem for WebSocket implementation.


## WebSocket
Constructing a WebSocket request is essentially an HTTP connection that includes a request to upgrade the connection to use WebSocket. WebSockets is built on TCP sockets - the WebSocket API re-assembles the TCP chunks of data into frames which are assembled into messages before invoking the message event handler once per message.


## Server Side
This program uses thin as server and fires the lambda block with ```thin.run```. [faye-websocket](https://github.com/faye/faye-websocket-ruby) provides an adapter to enable upgrading the handshake to websocket using thin.
```ruby
require 'faye-websocket'
require 'rack'

Faye::WebSocket.load_adapter('thin')

# use thin.run(wsServer,...) to run the lambda and get env
    thin = Rack::Handler.get('thin')
    thin.run(@wsServer, :Host => @socket_host, :Port => @socket_port)
```
The lambda block for initializing the WebSocket server:
```ruby
wsServer = lambda do |env|
      if Faye::WebSocket.websocket?(env)
        # It is a WebSocket connection
        ws = Faye::WebSocket.new(env)


        # .......


        # Return async Rack response
        ws.rack_response
      else
        # Normal HTTP request
        [200, { 'Content-Type' => 'text/plain' }, ['Hello, this is a normal HTTP Request.']]
      end
    end
```
Then simply use the available apis from faye-websocket: ```on :open```,```on :message``` and ```on :close```.


## Client side
Use EventMachine to run (multiple) clients. Start the EM reactor by using EM.run.
```ruby
require 'faye/websocket'
require 'eventmachine'

EM.run do
  ws = Faye::WebSocket::Client.new("ws://localhost:4567/")

  # ....

end
```
Within the EM run block, add all the websocket handlers ```on :open```,```on :message``` and ```on :close```.
Note that to be able to test in CLI with user input message, use new thread for command line input loop (looping so user can input multiple times) - so that waiting for user input won't block other on :message handler making messages being delayed.
```ruby
ws.on :message do |event|
  puts event.data
  Thread.new {
    loop {
        msg = $stdin.gets.chomp
        ws.send(msg)
      }
  }
end
```
Stop the EM loop by ```EM.stop```when the connection closes to gracefully exit the program.
```ruby
ws.on :close do |event|
  ws.nil
  puts "Connection cannot be established. Exiting..."
  EM.stop
end
```












