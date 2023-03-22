require 'ipaddr'
require 'vagrant/action/builtin/mixin_synced_folders'

module VagrantPlugins
  module Parallels
    module Action
      class PrepareNFSSettings
        include Vagrant::Action::Builtin::MixinSyncedFolders
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::nfs')
        end

        def call(env)
          @machine = env[:machine]
          @app.call(env)

          opts = {
            cached: !!env[:synced_folders_cached],
            config: env[:synced_folders_config],
            disable_usable_check: !!env[:test],
          }
          folders = synced_folders(env[:machine], **opts)

          if folders.has_key?(:nfs)
            @logger.info('Using NFS, preparing NFS settings by reading host IP and machine IP')
            add_ips_to_env!(env)
          end
        end

        # Extracts the proper host and guest IPs for NFS mounts and stores them
        # in the environment for the SyncedFolder action to use them in
        # mounting.
        #
        # The ! indicates that this method modifies its argument.
        def add_ips_to_env!(env)
          host_ip  = @machine.provider.driver.read_shared_interface[:ip]
          guest_ip = @machine.provider.driver.ssh_ip

          # If we couldn't determine either guest's or host's IP, then
          # it is probably a bug. Display an appropriate error message.
          raise Vagrant::Errors::NFSNoHostIP  if !host_ip
          raise Vagrant::Errors::NFSNoGuestIP if !guest_ip

          env[:nfs_host_ip]    = host_ip
          env[:nfs_machine_ip] = guest_ip
        end
      end
    end
  end
end
