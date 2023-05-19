require 'vagrant/util/platform'

module VagrantPlugins
  module Parallels
    class SyncedFolderMacVM < Vagrant.plugin('2', :synced_folder)
      def usable?(machine, raise_errors=false)
        # These synced folders only work if the provider is Parallels and the guest is *.macvm
        machine.provider_name == :parallels && Util::Common::is_macvm(machine)
      end

      def prepare(machine, folders, _opts)
        # TBD: Synced folders for *.macvm are not implemented yet
        return
      end

      def enable(machine, folders, _opts)
        # TBD: Synced folders for *.macvm are not implemented yet
        return
      end

      def disable(machine, folders, _opts)
        # TBD: Synced folders for *.macvm are not implemented yet
        return
      end

      def cleanup(machine, opts)
        # TBD: Synced folders for *.macvm are not implemented yet
        return
      end
    end
  end
end
