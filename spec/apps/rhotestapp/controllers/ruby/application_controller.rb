class ApplicationController < Rhoconnect::Controller::AppBase
  register Rhoconnect::EndPoint

  post '/login', :rc_handler => :authenticate,
                 :deprecated_route => {:verb => :post, :url => ['/application/clientlogin', '/api/application/clientlogin']}  do
    username = params[:login]
    password = params[:password] 
    session[:auth] = "delegated"
    raise RuntimeError.new('server error') if password == 'server error'
    raise LoginException.new('login exception') if password == 'wrongpass'
    return "different" if password == "diffuser"
    password == 'wrongpassnomsg' ? false : true  
  end

  get '/rps_login', :rc_handler => :rps_authenticate, 
                    :login_required => true do
    username = params[:login]
    password = params[:password]
    'rpsuser:secret' == [username,password].join(':') 
  end
end