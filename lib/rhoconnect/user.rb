require 'digest/sha1'

module Rhoconnect
  # Inspired by sinatra-authentication
  # Password uses simple sha1 digest for hashing
  class User < StoreOrm
    field :login,:string
    field :email,:string
    field :salt,:string
    field :hashed_password,:string
    set   :clients, :string
    field :admin, :int
    field :token_id, :string
    #set_all :users, :string

    class << self
      def create(fields={})
        raise ArgumentError.new("Empty login") if (fields[:login].nil? or fields[:login].empty?)
        raise ArgumentError.new("Reserved user id #{fields[:login]}") if fields[:login] && fields[:login] == '__shared__'
        fields[:id] = fields[:login]
        user = super(fields)
        if Rhoconnect.stats
          Rhoconnect::Stats::Record.set('users') { Store.incr('user:count') }
        else
          Store.incr('user:count')
        end
        user
      end

      def authenticate(login,password)
        return unless is_exist?(login)
        current_user = load(login)
        return if current_user.nil?
        return current_user if User.encrypt(password, current_user.salt) == current_user.hashed_password
      end

      # Rails like methods
      def all
        App.load(APP_NAME).users.members
      end

      def ping(params)
        if params['async']
          PingJob.enqueue(params)
        else
          PingJob.perform(params)
        end
      end
    end

    def new_password=(pass)
      self.password=(pass)
    end

    def password=(pass)
      @password = pass
      self.salt = User.random_string(10) if !self.salt
      self.hashed_password = User.encrypt(@password, self.salt)
    end

    def delete
      clients.members.each do |client_id|
        Client.load(client_id,{:source_name => '*'}).delete
      end
      self.token.delete if self.token
      if Rhoconnect.stats
        Rhoconnect::Stats::Record.set('users') { Store.decr('user:count') }
      else
        Store.decr('user:count')
      end
      super
    end

    def create_token
      if self.token_id && ApiToken.is_exist?(self.token_id)
        self.token.delete
      end
      fields = {:user_id => self.login}
      if self.login == 'rhoadmin'
        fields[:value] = Rhoconnect.api_token
      end
      self.token_id = ApiToken.create(fields).id
    end

    def token
      ApiToken.load(self.token_id)
    end

    def token=(value)
      if self.token_id && ApiToken.is_exist?(self.token_id)
        self.token.delete
      end
      self.token_id = ApiToken.create(:user_id => self.login, :value => value).id
    end

    def update(fields)
      fields.each do |key,value|
        self.send("#{key.to_sym}=", value) unless key == 'login'
      end
    end

    def to_hash
       res = {}
       self.class.fields.each do |field|
         res[field[:name].to_sym] = send(field[:name].to_sym) if field[:name] == 'login'
       end
       res
    end

    protected
    def self.encrypt(pass, salt)
      Digest::SHA1.hexdigest(pass+salt)
    end

    def self.random_string(len)
      chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
      newpass = ""
      1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
      return newpass
    end
  end
end