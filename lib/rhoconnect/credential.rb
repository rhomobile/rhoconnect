module Rhoconnect
  class Credential
    attr_accessor :login,:password,:token,:url
    
    def initialize(login,password,token,url)
      @login,@password,@token,@url = login,password,token,url
    end
  end
end