Execute.define_task do
  begin
    desc "spec", "Run source adapter specs"
    def spec
      require 'rspec/core/rake_task'

      files = File.join('spec','**','*_spec.rb')
      pattern = FileList[files]
      rspec_opts = "-fn -b --color"

      cmd = "bundle exec rspec #{pattern} #{rspec_opts}"
      puts cmd
      exec cmd
      # Another way run rspec examples
      # RSpec::Core::Runner.run(pattern, $stderr, $stdout)
    end
  rescue Exception => e
    puts "Run source adapter specs error: #{e.inspect}"
  end
end
