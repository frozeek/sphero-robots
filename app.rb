# Require base
require 'sinatra'
require 'redis'

require_relative 'lib/json_body_params'

connections = []

get '/' do
  erb :index
end

post '/run' do
  redis = Redis.connect
  redis.publish('message', params[:code])
  status 200
end

get '/stream', provides: 'text/event-stream' do
  stream :keep_open do |out|
    connections << out
    out.callback { connections.delete(out) }
  end
end

Thread.new do
  redis = Redis.connect
  redis.psubscribe('logging', 'logging.*') do |on|
    on.pmessage do |match, channel, message|
      connections.each { |out| out << "data: #{message}\n\n" }
    end
  end
end
