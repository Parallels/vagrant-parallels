module VagrantPlugins
  module Parallels
    module GuestLinuxCap
      class MountParallelsSharedFolder

        def self.mount_parallels_shared_folder(machine, name, guestpath, options)
          # Expand the guest path so we can handle things like "~/vagrant"
          expanded_guest_path = machine.guest.capability(
            :shell_expand_guest_path, guestpath)

          machine.communicate.tap do |comm|
            # clear prior symlink
            if comm.test("test -L \"#{expanded_guest_path}\"", :sudo => true)
              comm.sudo("rm \"#{expanded_guest_path}\"")
            end

            # clear prior directory if exists
            if comm.test("test -d \"#{expanded_guest_path}\"", :sudo => true)
              comm.sudo("rm -Rf \"#{expanded_guest_path}\"")
            end

            # create intermediate directories if needed
            intermediate_dir = File.dirname(expanded_guest_path)
            if !comm.test("test -d \"#{intermediate_dir}\"", :sudo => true)
              comm.sudo("mkdir -p \"#{intermediate_dir}\"")
            end

            # finally make the symlink
            comm.sudo("ln -s \"/media/psf/#{name}\" \"#{expanded_guest_path}\"")

            # Emit an upstart event if we can
            if comm.test("test -x /sbin/initctl")
              comm.sudo(
                "/sbin/initctl emit --no-wait vagrant-mounted MOUNTPOINT=#{expanded_guest_path}")
            end
          end
        end

        def self.unmount_parallels_shared_folder(machine, guestpath, options)
          machine.communicate.sudo("rm #{guestpath}", error_check: false)
        end
      end
    end
  end
end
