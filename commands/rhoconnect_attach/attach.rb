Execute.define_task do
  desc "attach", "Attach to rhoconnect console"
  def attach
    if dtach_installed?
      system "dtach -a #{rhoconnect_socket}"
    else
      "Cannot attach to rhoconnect console. 'dtach' program is not installed."
    end
  end
end