require 'faye/websocket'
require 'eventmachine'

# EM#run will start the EM reactor and keep running until told to stop
# EM#stop or EM#stop_event_loop
EM.run do
  ws = Faye::WebSocket::Client.new("ws://localhost:4567/")

  ws.on :open do |event|
    puts "Connected to the chat room server!"
  end

  ws.on :message do |event|
    puts event.data


    # use threads to prevent blocking on :message handler
    # if thread is not used, messages to other clients will
    # be delayed
    Thread.new {
      loop {
        msg = $stdin.gets.chomp
        ws.send(msg)
      }
      # msg = $stdin.gets.chomp
      # ws.send(msg)
    }
  end

  ws.on :close do |event|
    #puts [:close, event.code, event.reason]
    ws = nil
    puts "Cannot connect server. Exiting..."
    EM.stop   # if server terminates, stop EM and exit
  end



end
