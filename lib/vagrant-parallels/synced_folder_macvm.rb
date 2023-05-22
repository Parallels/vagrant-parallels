require 'vagrant/util/platform'

module VagrantPlugins
  module Parallels
    class SyncedFolderMacVM < Vagrant.plugin('2', :synced_folder)
      def usable?(machine, raise_errors=false)
        # These synced folders only work if the provider is Parallels and the guest is *.macvm
        machine.provider_name == :parallels && Util::Common::is_macvm(machine)
      end

      def prepare(machine, folders, _opts)
        # Setup shared folder definitions in the VM config.
        defs = []
        folders.each do |id, data|
          hostpath = data[:hostpath]
          if !data[:hostpath_exact]
            hostpath = Vagrant::Util::Platform.cygwin_windows_path(hostpath)
          end

          defs << {
            name: data[:plugin].capability(:mount_name, id, data),
            hostpath: hostpath.to_s,
          }
        end

        driver(machine).share_folders(defs)
      end

      def enable(machine, folders, _opts)
        # TBD: Synced folders for *.macvm are not implemented yet
        return
      end

      def disable(machine, folders, _opts)
        # Remove the shared folders from the VM metadata
        names = folders.map { |id, data| data[:plugin].capability(:mount_name, id, data) }
        driver(machine).unshare_folders(names)
      end

      def cleanup(machine, opts)
        driver(machine).clear_shared_folders if machine.id && machine.id != ''
      end

      # This is here so that we can stub it for tests
      def driver(machine)
        machine.provider.driver
      end
    end
  end
end
