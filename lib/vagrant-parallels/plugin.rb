begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant Parallels plugin must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.5.0"
  raise "The Vagrant Parallels plugin is only compatible with Vagrant 1.5+"
end

require_relative "version"

module VagrantPlugins
  module Parallels

    class Plugin < Vagrant.plugin("2")
      name "vagrant-parallels"
      description <<-EOF
      The Parallels provider allows Vagrant to manage and control
      Parallels-based virtual machines.
      EOF

      provider(:parallels) do
        require File.expand_path("../provider", __FILE__)
        Provider
      end

      config(:parallels, :provider) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      guest_capability(:darwin, :mount_parallels_shared_folder) do
        require_relative "guest_cap/darwin/mount_parallels_shared_folder"
        GuestDarwinCap::MountParallelsSharedFolder
      end

      guest_capability(:linux, :mount_parallels_shared_folder) do
        require_relative "guest_cap/linux/mount_parallels_shared_folder"
        GuestLinuxCap::MountParallelsSharedFolder
      end

      provider_capability("parallels", "public_address") do
        require_relative "cap/public_address"
        Cap::PublicAddress
      end

      provider_capability("parallels", "host_address") do
        require_relative "cap/host_address"
        Cap::HostAddress
      end

      synced_folder(:parallels) do
        require File.expand_path("../synced_folder", __FILE__)
        SyncedFolder
      end

    end

    autoload :Action, File.expand_path("../action", __FILE__)

    # Drop some autoloads in here to optimize the performance of loading
    # our drivers only when they are needed.
    module Driver
      autoload :Meta, File.expand_path("../driver/meta", __FILE__)
      autoload :PD_8, File.expand_path("../driver/pd_8", __FILE__)
      autoload :PD_9, File.expand_path("../driver/pd_9", __FILE__)
    end
  end
end