# Require base
require 'sinatra/base'
require 'rack/standards'
require 'lib/json_body_params'
require 'redis'

module SpheroController
  class App < Sinatra::Application
    configure do
      register Sinatra::JsonBodyParams
    end

    configure do
      disable :method_override
      set :show_exceptions, false
    end

    use Rack::Deflater
    use Rack::Standards

    error do |e|
      status 422
    end

    get '/' do
      erb :index
    end

    post '/run' do
      redis = Redis.connect
      redis.publish('message', params[:code])
      redirect to('/')
    end
  end
end
