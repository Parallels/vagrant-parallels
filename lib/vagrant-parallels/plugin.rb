begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant Parallels plugin must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < '1.5.0'
  raise 'The Vagrant Parallels plugin is only compatible with Vagrant 1.5+'
end

module VagrantPlugins
  module Parallels
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-parallels'
      description <<-EOF
      The Parallels provider allows Vagrant to manage and control
      Parallels Desktop virtual machines.
      EOF

      provider(:parallels, parallel: true, priority: 7) do
        # Setup logging and i18n
        setup_logging
        setup_i18n

        require_relative 'provider'
        Provider
      end

      config(:parallels, :provider) do
        require_relative 'config'
        Config
      end

      guest_capability(:darwin, :mount_parallels_shared_folder) do
        require_relative 'guest_cap/darwin/mount_parallels_shared_folder'
        GuestDarwinCap::MountParallelsSharedFolder
      end

      guest_capability(:darwin, :unmount_parallels_shared_folder) do
        require_relative 'guest_cap/darwin/mount_parallels_shared_folder'
        GuestDarwinCap::MountParallelsSharedFolder
      end

      guest_capability(:linux, :mount_parallels_shared_folder) do
        require_relative 'guest_cap/linux/mount_parallels_shared_folder'
        GuestLinuxCap::MountParallelsSharedFolder
      end

      guest_capability(:linux, :unmount_parallels_shared_folder) do
        require_relative 'guest_cap/linux/mount_parallels_shared_folder'
        GuestLinuxCap::MountParallelsSharedFolder
      end

      guest_capability(:linux, :prepare_psf_services) do
        require_relative 'guest_cap/linux/mount_parallels_shared_folder'
        GuestLinuxCap::MountParallelsSharedFolder
      end

      guest_capability(:linux, :install_parallels_tools) do
        require_relative 'guest_cap/linux/install_parallels_tools'
        GuestLinuxCap::InstallParallelsTools
      end

      provider_capability(:parallels, :public_address) do
        require_relative 'cap/public_address'
        Cap::PublicAddress
      end

      provider_capability(:parallels, :host_address) do
        require_relative 'cap/host_address'
        Cap::HostAddress
      end

      provider_capability(:parallels, :nic_mac_addresses) do
        require_relative 'cap/nic_mac_addresses'
        Cap::NicMacAddresses
      end

      synced_folder(:parallels) do
        require_relative 'synced_folder'
        SyncedFolder
      end

      # This initializes the internationalization strings.
      def self.setup_i18n
        I18n.load_path << File.expand_path('locales/en.yml', Parallels.source_root)
        I18n.reload!
      end

      # This sets up our log level to be whatever VAGRANT_LOG is.
      def self.setup_logging
        require 'log4r'

        level = nil
        begin
          level = Log4r.const_get(ENV['VAGRANT_LOG'].upcase)
        rescue NameError
          # This means that the logging constant wasn't found,
          # which is fine. We just keep `level` as `nil`. But
          # we tell the user.
          level = nil
        end

        # Some constants, such as "true" resolve to booleans, so the
        # above error checking doesn't catch it. This will check to make
        # sure that the log level is an integer, as Log4r requires.
        level = nil if !level.is_a?(Integer)

        # Set the logging level on all "vagrant" namespaced
        # logs as long as we have a valid level.
        if level
          logger = Log4r::Logger.new('vagrant_parallels')
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
          logger = nil
        end
      end
    end

    # Drop some autoloads in here to optimize the performance of loading
    # our drivers only when they are needed.
    module Driver
      autoload :Meta, File.expand_path('../driver/meta', __FILE__)
      autoload :PD_8, File.expand_path('../driver/pd_8', __FILE__)
      autoload :PD_9, File.expand_path('../driver/pd_9', __FILE__)
      autoload :PD_10, File.expand_path('../driver/pd_10', __FILE__)
      autoload :PD_11, File.expand_path('../driver/pd_11', __FILE__)
    end

    module Model
      autoload :ForwardedPort, File.expand_path('../model/forwarded_port', __FILE__)
    end

    module Util
      autoload :CompileForwardedPorts, File.expand_path('../util/compile_forwarded_ports', __FILE__)
    end
  end
end
