require 'eventmachine'
require 'em-websocket'
require 'base64'

class WebSocketServer
  def self.error(description, websocket = nil)
    websocket.send("error=>"+description) unless websocket.nil?
    puts("Error: #{description}")
  end

  def self.deliver(description, websocket = nil)
    websocket.send(description) unless websocket.nil?
    puts("Sending: #{description}")
  end

  def self.run
    EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|
      storage_path = 'storage'
      upload_file = {}

      ws.onopen { upload_file[ws] = {} }
      ws.onclose {
        file = upload_file[ws]['file']
        if file
          file.close rescue nil
        end
        upload_file.delete ws
      }

      ws.onmessage do |message|
        if upload_file[ws]['in_progress'] && message.start_with?('upload=>')
          message = Base64.decode64 message[('upload=>'.size)..-1]
          upload_file[ws]['file'] << message
          upload_file[ws]['index'] += message.size
          deliver("response=>upload||#{upload_file[ws]['index']}",ws)
          if upload_file[ws]['index'] >= upload_file[ws]['size']
            upload_file[ws]['in_progress'] = false
            upload_file[ws]['file'].close()
            error('File size mismatch') unless upload_file[ws]['index'] == upload_file[ws]['size']
          end
        elsif message=~/^query=>(.*)$/i

          args = $1.split('||')
          query = args.shift
          puts "#{query} => #{args}"

          if query=~/exist/
            if args.size==1
              filename = args.shift.gsub(/^.*[\/\\](?=\w)|[\/\\][\w\s]*$/,'')
              deliver("response=>exist||#{File.size?(storage_path+'/'+filename)||0}",ws)
            else
              error('Incorrect parameters',ws)
            end
          end
        elsif message=~/^command=>(.*)$/i

          args = $1.split('||')
          query = args.shift

          if query=~/upload/
            if args.size==3
              upload_file[ws]['name'] = args[0]
              upload_file[ws]['size'] = args[1].to_i
              upload_file[ws]['index'] = args[2].to_i
              puts "#{ws} upload: #{args[0]} #{args[1]} #{args[2]}"
              mode = ((upload_file[ws]['index'] == 0) ? 'w' : 'a')
              upload_file[ws]['file'] = File.new(storage_path+"/"+upload_file[ws]['name'], mode)
              if upload_file[ws]['file']
                upload_file[ws]['in_progress'] = true
              else
                error('Failed to open file on server',ws)
              end
            else
              error('Incorrect parameters',ws)
            end
          end
        end
      end
    end
  end
end
