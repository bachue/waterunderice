require 'thin'
require 'yaml'
require_relative 'websocket_server'

EventMachine.run {
  puts "Start WebSocketServer ..."
  WebSocketServer.run
  puts "Start Web Server ..."
  options = YAML.load_file('config.yml')
  options = options.each_with_object({}) {|(k, v), h| h[k.to_sym] = v }
  Thin::Controllers::Controller.new(options).start
}
