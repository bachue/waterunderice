require 'sinatra/base'

class Server < Sinatra::Base
  enable :logging
  set :environment, :production
  set :root, File.dirname(__FILE__)
  set :public, File.dirname(__FILE__) + "/public"
  set :views, File.dirname(__FILE__) + "/views"

  get '/' do
    erb :index
  end
end
