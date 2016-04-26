Execute.define_task do
  desc "secret", "Generate a cryptographically secure secret session key"
  def secret
    begin
      require 'securerandom'
      puts SecureRandom.hex(64)
    rescue LoadError
      puts "Missing secure random generator.  Try running `rhoconnect secret` in a rails application instead."
    end #begin
  end #secret
end #do