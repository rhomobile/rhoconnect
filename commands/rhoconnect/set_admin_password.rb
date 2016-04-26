Execute.define_task do
  desc "set-admin-password", "Set the admin password"
  def set_admin_password
    token = get_token(false)
    new_pass,new_pass_confirm = '',''
    begin
      system "stty -echo"
      new_pass = ask "\nnew admin password: "
      new_pass_confirm = ask "\nconfirm new admin password: "
      system "stty echo"
    rescue NoMethodError, Interrupt
      system "stty echo"
      exit
    end #begin
    if new_pass == ''
      puts "\nNew password can't be empty."
    elsif new_pass == new_pass_confirm
      puts ""
      url = config[:syncserver]
      res = RestClient.put("#{url}/rc/v1/users/rhoadmin",
        { :attributes => { :new_password => new_pass }}.to_json, {:content_type => :json, 'X-RhoConnect-API-TOKEN' => token})
      puts "Admin password is successfully updated" if res.code == 200
    else
      puts "\nNew password and confirmation must match."
    end
  end
end