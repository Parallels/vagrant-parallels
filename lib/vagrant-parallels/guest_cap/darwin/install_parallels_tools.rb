module VagrantPlugins
  module Parallels
    module GuestDarwinCap
      class InstallParallelsTools

        def self.install_parallels_tools(machine)
          machine.communicate.tap do |comm|
            arch = ''
            comm.execute("uname -p") { |type, data| arch << data if type == :stdout }

            tools_iso_path = File.expand_path(
              machine.provider.driver.read_guest_tools_iso_path("darwin", arch),
              machine.env.root_path
            )
            remote_file = '/tmp/prl-tools-mac.iso'
            mount_point = "/media/prl-tools-lin_#{rand(100000)}/"

            comm.upload(tools_iso_path, remote_file)

            # Create mount point directory if needed
            if !comm.test("test -d \"#{mount_point}\"", :sudo => true)
              comm.sudo("mkdir -p \"#{mount_point}\"")
            end

            # Mount ISO and install Parallels Tools
            comm.sudo("hdiutil attach #{remote_file} -mountpoint #{mount_point}")
            comm.sudo("installer -pkg '#{mount_point}/Install.app/Contents/Resources/Install.mpkg' -target /")
            comm.sudo("hdiutil detach '#{mount_point}'")

            comm.sudo("rm -Rf \"#{mount_point}\"")
            comm.sudo("rm -f \"#{remote_file}\"")
          end
        end
      end
    end
  end
end
