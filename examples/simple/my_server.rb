# FIXME: This is a temporary server to handle rps token registration
class MyServer < Rhoconnect::Server
  post '/rps/token' do
  	user = "tuser"
  	User.create(:login => user)
  	current_app.users << user
	fields = {:user_id => user}
    fields[:app_id] = 'application'
    fields[:device_type] = 'rhoconnect_push'
    fields[:device_pin] = params['token']
    Client.create(fields)
  	status 200
  end
end