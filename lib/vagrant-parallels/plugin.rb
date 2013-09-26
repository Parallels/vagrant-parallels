begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant Parallels plugin must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.2.0"
  raise "The Vagrant Parallels plugin is only compatible with Vagrant 1.2+"
end

module VagrantPlugins
  module Parallels

    class Plugin < Vagrant.plugin("2")
      name "Parallels"
      description <<-EOF
      The Parallels provider allows Vagrant to manage and control
      Parallels-based virtual machines.
      EOF

      provider(:parallels) do
        require File.expand_path("../provider", __FILE__)

        setup_logging
        setup_i18n

        Provider
      end

      # This initializes the internationalization strings.
      def self.setup_i18n
        I18n.load_path << File.expand_path("locales/en.yml", Parallels.source_root)
        I18n.reload!
      end

      # This sets up our log level to be whatever VAGRANT_LOG is.
      def self.setup_logging
        require "log4r"

        level = nil
        begin
          level = Log4r.const_get(ENV["VAGRANT_LOG"].upcase)
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
          logger = Log4r::Logger.new("vagrant_parallels")
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
          logger = nil
        end
      end

      # config(:parallels, :provider) do
      #   require File.expand_path("../config", __FILE__)
      #   Config
      # end

      guest_capability(:darwin, :mount_parallels_shared_folder) do
        require_relative "guest_cap/darwin/mount_parallels_shared_folder"
        GuestDarwinCap::MountParallelsSharedFolder
      end

      guest_capability(:linux, :mount_parallels_shared_folder) do
        require_relative "guest_cap/linux/mount_parallels_shared_folder"
        GuestLinuxCap::MountParallelsSharedFolder
      end

    end

    module Driver
      autoload :PrlCtl, File.expand_path("../driver/prl_ctl", __FILE__)
    end
  end
end