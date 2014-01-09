begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant Parallels plugin must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.4.0"
  raise "The Vagrant Parallels plugin is only compatible with Vagrant 1.4+"
end

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

      synced_folder(:parallels) do
        require File.expand_path("../synced_folder", __FILE__)
        SyncedFolder
      end

    end

    module Driver
      autoload :PrlCtl, File.expand_path("../driver/prl_ctl", __FILE__)
    end

    module Util
      def generate_name(path, suffix='')
        "#{path.basename.to_s.gsub(/[^-a-z0-9_]/i, '')}#{suffix}_#{Time.now.to_i}"
      end
    end
  end
end