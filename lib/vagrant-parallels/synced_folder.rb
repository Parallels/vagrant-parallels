require 'vagrant/util/platform'

module VagrantPlugins
  module Parallels
    class SyncedFolder < Vagrant.plugin('2', :synced_folder)
      def usable?(machine, raise_errors=false)
        # These synced folders only work if the provider is Parallels and the guest is not *.macvm
        machine.provider_name == :parallels &&
          machine.provider_config.functional_psf &&
          !Util::Common::is_macvm(machine)
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
        # short guestpaths first, so we don't step on ourselves
        folders = folders.sort_by do |id, data|
          if data[:guestpath]
            data[:guestpath].length
          else
            # A long enough path to just do this at the end.
            10000
          end
        end

        # Parallels Shared Folder services can override Vagrant synced folder
        # configuration. These services should be pre-configured.
        if machine.guest.capability?(:prepare_psf_services)
          machine.guest.capability(:prepare_psf_services)
        end

        # Go through each folder and mount
        machine.ui.output(I18n.t('vagrant.actions.vm.share_folders.mounting'))
        folders.each do |id , data|
          if data[:guestpath]
            # Guest path specified, so mount the folder to specified point
            machine.ui.detail(I18n.t('vagrant.actions.vm.share_folders.mounting_entry',
                                     guestpath: data[:guestpath],
                                     hostpath: data[:hostpath]))

            # Dup the data so we can pass it to the guest API
            data = data.dup

            # Calculate the owner and group
            ssh_info = machine.ssh_info
            data[:owner] ||= ssh_info[:username]
            data[:group] ||= ssh_info[:username]

            # Mount the actual folder
            machine.guest.capability(
              :mount_parallels_shared_folder,
              data[:plugin].capability(:mount_name, id, data),
              data[:guestpath],
              data
            )
          else
            # If no guest path is specified, then automounting is disabled
            machine.ui.detail(I18n.t('vagrant.actions.vm.share_folders.nomount_entry',
                                   :hostpath => data[:hostpath]))
          end
        end
      end

      def disable(machine, folders, _opts)
        if machine.guest.capability?(:unmount_parallels_shared_folder)
          folders.each do |id, data|
            machine.guest.capability(
              :unmount_parallels_shared_folder,
              data[:guestpath], data)
          end
        end

        # Remove the shared folders from the VM metadata
        names = folders.map { |id, data| data[:plugin].capability(:mount_name, id, data) }
        driver(machine).unshare_folders(names)
      end

      def cleanup(machine, opts)
        driver(machine).clear_shared_folders if machine.id && machine.id != ''
      end

      protected

      # This is here so that we can stub it for tests
      def driver(machine)
        machine.provider.driver
      end
    end
  end
end
