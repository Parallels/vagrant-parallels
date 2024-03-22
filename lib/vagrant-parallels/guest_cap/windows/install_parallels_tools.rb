module VagrantPlugins
  module Parallels
    module GuestWindowsCap
      class InstallParallelsTools
        def self.install_parallels_tools(machine)
          machine.communicate.tap do |comm|
            # Get the host arch. This is safe even if an older x86-only Vagrant version is used.
            arch = `arch -64 uname -m`.chomp

            pti_agent_path = File.expand_path(
              machine.provider.driver.read_guest_tools_iso_path('windows', arch),
              machine.env.root_path
            )

            remote_file = '$env:TEMP\parallels-tools-win.iso'
            comm.upload(pti_agent_path, remote_file)

            install_script = <<-EOH
            $MountedISOs=Mount-DiskImage -PassThru #{remote_file}
            $Volume=$MountedISOs | Get-Volume
            $DriveLetter=$Volume.DriveLetter

            Start-Process -FilePath ($DriveLetter + ":/PTAgent.exe") `
              -ArgumentList "/install_silent" `
              -Verb RunAs `
              -Wait
            EOH

            cleanup_script = <<-EOH
            Dismount-DiskImage -ImagePath #{remote_file}
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
