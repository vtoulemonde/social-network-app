require 'rack'
require_relative 'app/main'


app = App.new
app = Rack::ShowExceptions.new app
app = Rack::Reloader.new app
app = Rack::ShowStatus.new app
app = Rack::Session::Cookie.new app
app = Rack::Static.new(app, {:urls => ["/public"]})

Rack::Handler::WEBrick.run app