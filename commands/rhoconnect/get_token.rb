Execute.define_task do
desc "get-token", "Fetch current api token from rhoconnect"
  def get_token(save = true)
    require 'rest_client'
    url = config[:syncserver]
    password = ''
    begin
      system "stty -echo"
      password = ask "admin password: "
      system "stty echo"
    rescue NoMethodError, Interrupt
      system "stty echo"
      exit
    end
    puts ''
    begin
      token = RestClient.post("#{url}/rc/v1/system/login",
        { :login => 'rhoadmin', :password => password }.to_json, :content_type => :json)
    rescue Exception => e
      puts e.message
      puts "Rhoconnect server is not running or invalid credentials."
      exit
    end
    if save
      token_file = File.join(ENV['HOME'],'.rhoconnect_token')
      File.open(token_file,'w') {|f| f.write(token)}
      puts "Token is saved in: #{token_file}"
    end
    token
  end
end