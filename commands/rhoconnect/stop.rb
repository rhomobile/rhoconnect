Execute.define_task do
  desc "stop", "Stop rhoconnect server"
  def stop
    if windows?
      File.delete "#{rhoconnect_pid}" if system("FOR /F %A in (#{rhoconnect_pid}) do taskkill /F /PID %A")
    else
      if File.exist?("#{rhoconnect_pid}")
        pid = `cat #{rhoconnect_pid}`
        puts "Sending a QUIT signal to process #{pid}"
        system "kill -3 #{pid}"
        3.times do
          sleep 1
          return if !File.exist?("#{rhoconnect_pid}")
        end

        puts "Process #{pid} is still running. Sending a KILL signal to it ..."
        system "kill -9 #{pid}"
        File.delete(rhoconnect_pid)
      end
    end
  end
end