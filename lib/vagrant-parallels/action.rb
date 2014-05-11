require "vagrant/action/builder"

module VagrantPlugins
  module Parallels
    module Action
      # Include the built-in modules so that we can use them as top-level
      # things.
      include Vagrant::Action::Builtin

      # This action boots the VM, assuming the VM is in a state that requires
      # a bootup (i.e. not saved).
      def self.action_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use SetPowerConsumption
          b.use SetName
          b.use Provision
          b.use PrepareNFSValidIds
          b.use SyncedFolderCleanup
          b.use SyncedFolders
          b.use PrepareNFSSettings
          b.use Network
          b.use ClearNetworkInterfaces
          b.use SetHostname
          # b.use SaneDefaults
          b.use Customize, "pre-boot"
          b.use Boot
          b.use Customize, "post-boot"
          b.use WaitForCommunicator, [:starting, :running]
          b.use CheckGuestTools
        end
      end

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant.commands.common.vm_not_created")
              next
            end

            b1.use Call, DestroyConfirm do |env2, b2|
              if !env2[:result]
                b2.use Message, I18n.t("vagrant.commands.destroy.will_not_destroy",
                                       :name => env2[:machine].name)
                next
              end

              b2.use EnvSet, :force_halt => true
              b2.use action_halt
              b2.use Destroy
              b2.use DestroyUnusedNetworkInterfaces
              b2.use ProvisionerCleanup
              b2.use PrepareNFSValidIds
              b2.use SyncedFolderCleanup
            end
          end
        end
      end

      # This is the action that is primarily responsible for halting
      # the virtual machine, gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant.commands.common.vm_not_created")
              next
            end

            b1.use Call, IsState, :suspended do |env2, b2|
              if env2[:result]
                b2.use Resume
              end
            end

            b1.use Call, GracefulHalt, :stopped, :running do |env2, b2|
              if !env2[:result]
                b2.use ForcedHalt
              end
            end
          end
        end
      end

      # This action packages the virtual machine into a single box file.
      def self.action_package
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant.commands.common.vm_not_created")
              next
            end

            b1.use SetupPackageFiles
            b1.use action_halt
            b1.use PrepareNFSValidIds
            b1.use SyncedFolderCleanup
            b1.use Package
            b1.use Export
            b1.use PackageConfigFiles
          end
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant.commands.common.vm_not_created")
              next
            end

            b1.use Call, IsState, :running do |env2, b2|
              if !env2[:result]
                b2.use Message, I18n.t("vagrant.commands.common.vm_not_running")
                next
              end

              b2.use Provision
            end
          end
        end
      end

      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant.commands.common.vm_not_created")
              next
            end

            b1.use action_halt
            b1.use action_start
          end
        end
      end

      # This is the action that is primarily responsible for resuming
      # suspended machines.
      def self.action_resume
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant.commands.common.vm_not_created")
              next
            end

            b1.use Resume
            b1.use WaitForCommunicator, [:resuming, :running]
          end
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant.commands.common.vm_not_created")
              next
            end

            b1.use Call, IsState, :running do |env2, b2|
              if !env2[:result]
                b2.use Message, I18n.t("vagrant.commands.common.vm_not_running")
                next
              end

              b2.use SSHExec
            end
          end
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant.commands.common.vm_not_created")
              next
            end

            b1.use Call, IsState, :running do |env2, b2|
              if !env2[:result]
                b2.use Message, I18n.t("vagrant.commands.common.vm_not_running")
                next
              end

              b2.use SSHRun
            end
          end
        end
      end

      # This action starts a VM, assuming it is already imported and exists.
      # A precondition of this action is that the VM exists.
      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use BoxCheckOutdated
          b.use Call, IsState, :running do |env1, b1|
            # If the VM is running, then our work here is done, exit
            if env1[:result]
              b1.use Message, I18n.t("vagrant_parallels.commands.common.vm_already_running")
              next
            end

            b1.use Call, IsState, :suspended do |env2, b2|
              if env2[:result]
                # The VM is suspended, so just resume it
                b2.use action_resume
                next
              end

              # The VM is not saved, so we must have to boot it up
              # like normal. Boot!
              b2.use action_boot
            end
          end
        end
      end

      # This is the action that is primarily responsible for suspending
      # the virtual machine.
      def self.action_suspend
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t("vagrant.commands.common.vm_not_created")
              next
            end

            b1.use Suspend
          end
        end
      end

      # This action brings the machine up from nothing, including importing
      # the box, configuring metadata, and booting.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          # Handle box_url downloading early so that if the Vagrantfile
          # references any files in the box or something it all just
          # works fine.
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use HandleBox
            end
          end

          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            # If the VM is NOT created yet, then do the setup steps
            if env1[:result]
              b1.use Customize, "pre-import"
              b1.use Import
            end
          end
          b.use action_start
        end
      end

      autoload :Boot, File.expand_path("../action/boot", __FILE__)
      autoload :CheckGuestTools, File.expand_path("../action/check_guest_tools", __FILE__)
      autoload :ClearNetworkInterfaces, File.expand_path("../action/clear_network_interfaces", __FILE__)
      autoload :Customize, File.expand_path("../action/customize", __FILE__)
      autoload :Destroy, File.expand_path("../action/destroy", __FILE__)
      autoload :DestroyUnusedNetworkInterfaces, File.expand_path("../action/destroy_unused_network_interfaces", __FILE__)
      autoload :Export, File.expand_path("../action/export", __FILE__)
      autoload :ForcedHalt, File.expand_path("../action/forced_halt", __FILE__)
      autoload :Import, File.expand_path("../action/import", __FILE__)
      autoload :Network, File.expand_path("../action/network", __FILE__)
      autoload :Package, File.expand_path("../action/package", __FILE__)
      autoload :PackageConfigFiles, File.expand_path("../action/package_config_files", __FILE__)
      autoload :PrepareNFSSettings, File.expand_path("../action/prepare_nfs_settings", __FILE__)
      autoload :PrepareNFSValidIds, File.expand_path("../action/prepare_nfs_valid_ids", __FILE__)
      autoload :Resume, File.expand_path("../action/resume", __FILE__)
      autoload :SetupPackageFiles, File.expand_path("../action/setup_package_files", __FILE__)
      autoload :SetName, File.expand_path("../action/set_name", __FILE__)
      autoload :SetPowerConsumption, File.expand_path("../action/set_power_consumption", __FILE__)
      autoload :Suspend, File.expand_path("../action/suspend", __FILE__)
    end
  end
end
