require 'ipaddr'
require "vagrant/action/builtin/mixin_synced_folders"

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
            @logger.info("Using NFS, preparing NFS settings by reading host IP and machine IP")
            add_ips_to_env!(env)
          end
        end

        # Extracts the proper host and guest IPs for NFS mounts and stores them
        # in the environment for the SyncedFolder action to use them in
        # mounting.
        #
        # The ! indicates that this method modifies its argument.
        def add_ips_to_env!(env)
          host_ip = @machine.provider.driver.read_shared_interface[:ip]

          if !host_ip
            # If we couldn't determine host's IP, then it is probably a bug.
            # Display an appropriate error message.
            raise Vagrant::Errors::NFSNoHostIP
          end

          env[:nfs_host_ip]    = host_ip
          env[:nfs_machine_ip] = read_machine_ip
        end

        # Returns the IPv4 addresses of the guest by looking at VM options.
        #
        # For DHCP interfaces, the ip address will be present at the option
        # value only after VM boot
        #
        # @return [String] ip addresses
        def read_machine_ip
          # We need to wait for the guest's IP to show up as a VM option.
          # Retry thresholds are relatively high since we might need to wait
          # for DHCP, but even static IPs can take a second or two to appear.
          retryable(retry_options.merge(on: Errors::ParallelsVMOptionNotFound)) do
            ips = @machine.provider.driver.read_vm_option('ip').split(' ')
            ips.select! { |ip| IPAddr.new(ip).ipv4? }.sort
          end
        rescue Errors::ParallelsVMOptionNotFound
          # Display an appropriate error message.
          raise Vagrant::Errors::NFSNoGuestIP
        end

        # Separating these out so we can stub out the sleep in tests
        def retry_options
          {tries: 7, sleep: 2}
        end
      end
    end
  end
end
