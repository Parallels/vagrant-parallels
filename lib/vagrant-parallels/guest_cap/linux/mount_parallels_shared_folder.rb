module VagrantPlugins
  module Parallels
    module GuestLinuxCap
      class MountParallelsSharedFolder

        def self.mount_parallels_shared_folder(machine, name, guestpath, options)
          machine.communicate.tap do |comm|
            # clear prior symlink
            if comm.test("test -L \"#{guestpath}\"", :sudo => true)
              comm.sudo("rm \"#{guestpath}\"")
            end

            # clear prior directory if exists
            if comm.test("test -d \"#{guestpath}\"", :sudo => true)
              comm.sudo("rm -Rf \"#{guestpath}\"")
            end

            # create intermediate directories if needed
            intermediate_dir = File.dirname(guestpath)
            if !comm.test("test -d \"#{intermediate_dir}\"", :sudo => true)
              comm.sudo("mkdir -p \"#{intermediate_dir}\"")
            end

            # finally make the symlink
            comm.sudo("ln -s \"/media/psf/#{name}\" \"#{guestpath}\"")
          end
        end
      end
    end
  end
end
