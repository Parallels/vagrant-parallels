require 'log4r'

module VagrantPlugins
  module Parallels
    module GuestLinuxCap
      class InstallParallelsTools

        def self.install_parallels_tools(machine)
          if ptiagent_usable?(machine)
            machine.communicate.sudo('ptiagent-cmd --install')
          else
            machine.communicate.tap do |comm|
              arch = ''
              comm.execute("uname -p") { |type, data| arch << data if type == :stdout }

              tools_iso_path = File.expand_path(
                machine.provider.driver.read_guest_tools_iso_path("linux", arch),
                machine.env.root_path
              )
              remote_file = '/tmp/prl-tools-lin.iso'
              mount_point = "/media/prl-tools-lin_#{rand(100000)}/"

              comm.upload(tools_iso_path, remote_file)

              # Create mount point directory if needed
              if !comm.test("test -d \"#{mount_point}\"", :sudo => true)
                comm.sudo("mkdir -p \"#{mount_point}\"")
              end

              # Mount ISO and install Parallels Tools
              comm.sudo("mount -o loop #{remote_file} #{mount_point}")
              comm.sudo("#{mount_point}/install --install-unattended-with-deps")
              comm.sudo("umount -f \"#{mount_point}\"")

              comm.sudo("rm -Rf \"#{mount_point}\"")
              comm.sudo("rm -f \"#{remote_file}\"")
            end
          end
        end

        private

        # This helper detects is Parallels Tools Installation Agent (PTIAgent)
        # available and can be used
        def self.ptiagent_usable?(machine)
          # Parallels Desktop 9 or higher should be installed on the host and
          # 'ptiagent-cmd' binary should be available on the guest

          machine.provider_name == :parallels &&
          Gem::Version.new(machine.provider.driver.version) >= Gem::Version.new('9') &&
          machine.communicate.test('which ptiagent-cmd', :sudo => true)
        end
      end
    end
  end
end
