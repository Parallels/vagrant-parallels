module VagrantPlugins
  module Parallels
    module GuestWindowsCap
      class InstallParallelsTools
        def self.install_parallels_tools(machine)
          machine.communicate.tap do |comm|
            pti_agent_path = File.expand_path(
              machine.provider.driver.read_guest_tools_iso_path('windows'),
              machine.env.root_path
            )

            remote_file = '$env:TEMP\PTIAgent.exe'
            comm.upload(pti_agent_path, remote_file)

            install_script = <<-EOH
            Start-Process -FilePath #{remote_file} `
              -ArgumentList "/install_silent" `
              -Verb RunAs `
              -Wait
            EOH

            cleanup_script = <<-EOH
            If (Test-Path #{remote_file}){
              Remove-Item #{remote_file}
            }
            EOH

            comm.execute(install_script)
            comm.execute(cleanup_script)
          end
        end
      end
    end
  end
end
