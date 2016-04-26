# NOTE: On Windows Process.fork is implemented in a way
# that it re-starts the parent command with an additional "child#0"
# argument. Naturally, this leads to Thor rejecting that 2nd invocation
# since the original command is not supposed to have arguments.
# To overcome this issue all Background commands
# should have an optional fictitious parameter (which is not used)
# but exists merely to support Windows Process.fork artificial implementation
Execute.define_task do
  desc "startdebug [CHILDNAME]", "Start rhoconnect server in debug mode (Rhostudio) - this is an internal command", :hide => true
  def startdebug(childname=nil)
    cmd = (jruby?) ? trinidad? : (thin? || mongrel? || report_missing_server)
    ENV['DEBUG'] = 'yes'
    require 'win32/process' if windows?

    p1 = Process.fork {
      if windows?
        puts 'Starting rhoconnect ...'
        system "#{cmd} config.ru -P #{rhoconnect_pid}"
      elsif jruby?
        puts 'Starting rhoconnect in jruby environment...'
        system "#{cmd} -r config.ru"
      else
        system "#{cmd} config.ru -P #{rhoconnect_pid}"
      end
    }
    Process.detach(p1)

    exit
  end #startdebug
end
