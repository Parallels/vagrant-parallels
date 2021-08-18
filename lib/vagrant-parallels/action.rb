require 'vagrant/action/builder'

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
          b.use CheckSharedInterface
          b.use SetName
          b.use ClearForwardedPorts
          b.use Provision
          b.use PrepareForwardedPortCollisionParams
          b.use HandleForwardedPortCollisions
          b.use PrepareNFSValidIds
          b.use SyncedFolderCleanup
          b.use SyncedFolders
          b.use PrepareNFSSettings
          b.use Network
          b.use ClearNetworkInterfaces
          b.use ForwardPorts
          b.use SetHostname
          b.use Customize, 'pre-boot'
          b.use Boot
          b.use Customize, 'post-boot'
          b.use WaitForCommunicator, [:starting, :running]
          b.use Customize, 'post-comm'
          b.use HandleGuestTools
        end
      end

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            b1.use Call, DestroyConfirm do |env2, b2|
              if !env2[:result]
                b2.use Message, I18n.t('vagrant.commands.destroy.will_not_destroy',
                                       :name => env2[:machine].name)
                next
              end

              # Do not resume && halt the suspended VM, just delete it
              b2.use Call, IsState, :suspended do |env3, b3|
                if !env3[:result]
                  b3.use EnvSet, :force_halt => true
                  b3.use action_halt
                end
              end

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
          b.use CheckSharedInterface
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            # Resume/Unpause the VM if needed.
            b1.use Resume

            b1.use Call, GracefulHalt, :stopped, :running do |env2, b2|
              if !env2[:result]
                b2.use ForcedHalt
              end
            end

            b1.use ClearForwardedPorts
          end
        end
      end

      # This action packages the virtual machine into a single box file.
      def self.action_package
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            b1.use SetupPackageFiles
            b1.use action_halt
            b1.use PrepareNFSValidIds
            b1.use SyncedFolderCleanup
            b1.use Package
            b1.use Export
            b1.use PackageConfigFiles
            b1.use PackageVagrantfile
          end
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use CheckSharedInterface
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            b1.use Call, IsState, :running do |env2, b2|
              if !env2[:result]
                b2.use Message, I18n.t('vagrant.commands.common.vm_not_running')
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
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
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
          b.use CheckSharedInterface
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            b1.use PrepareForwardedPortCollisionParams
            b1.use HandleForwardedPortCollisions
            b1.use ForwardPorts
            b1.use Resume
            b1.use Provision
            b1.use WaitForCommunicator, [:resuming, :running]
          end
        end
      end

      def self.action_snapshot_delete
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
            else
              b1.use SnapshotDelete
            end
          end
        end
      end

      # This is the action that is primarily responsible for saving a snapshot
      def self.action_snapshot_restore
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            b1.use SnapshotRestore
            b1.use Call, IsEnvSet, :snapshot_delete do |env2, b2|
              if env2[:result]
                b2.use action_snapshot_delete
              end
            end
          end
        end
      end

      # This is the action that is primarily responsible for saving a snapshot
      def self.action_snapshot_save
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
            else
              b1.use SnapshotSave
            end
          end
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use CheckSharedInterface
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            b1.use Call, IsState, :running do |env2, b2|
              if !env2[:result]
                raise Vagrant::Errors::VMNotRunningError
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
          b.use CheckSharedInterface
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            b1.use Call, IsState, :running do |env2, b2|
              if !env2[:result]
                raise Vagrant::Errors::VMNotRunningError
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
            # If the VM is running, run the necessary provisioners
            if env1[:result]
              b1.use action_provision
              next
            end

            b1.use Call, IsState, :suspended do |env2, b2|
              if env2[:result]
                # The VM is suspended, go to resume
                b2.use action_resume
                next
              end

              b2.use Call, IsState, :paused do |env3, b3|
                if env3[:result]
                  # The VM is paused, just run the Resume action to unpause it
                  b3.use Resume
                  next
                end

                # The VM is not suspended or paused, so we must have to
                # boot it up like normal. Boot!
                b3.use action_boot
              end
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
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            b1.use ClearForwardedPorts
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
              b1.use Customize, 'pre-import'
              b1.use BoxRegister
              b1.use PrepareClone
              b1.use PrepareCloneSnapshot
              b1.use Import
              b1.use BoxUnregister
              b1.use SaneDefaults
              b1.use Customize, 'post-import'
            end
          end
          b.use action_start
        end
      end

      # This action simply reboots the VM. It is executed right after
      # Parallels Tools installation or upgrade.
      def self.action_simple_reboot
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, GracefulHalt, :stopped, :running do |env2, b2|
            if !env2[:result]
              b2.use ForcedHalt
            end
          end

          b.use Customize, 'pre-boot'
          b.use Boot
          b.use Customize, 'post-boot'
          b.use WaitForCommunicator, [:starting, :running]
          b.use Customize, 'post-comm'
        end
      end

      # This is the action that is called to sync folders to a running machine
      # without a reboot. It is used by the docker provider to link synced
      # folders on the host machine as volumes into the docker containers.
      def self.action_sync_folders
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env1, b1|
            if env1[:result]
              b1.use Message, I18n.t('vagrant.commands.common.vm_not_created')
              next
            end

            b1.use Call, IsState, :running do |env2, b2|
              if !env2[:result]
                b2.use Message, I18n.t('vagrant.commands.common.vm_not_running')
                next
              end
              b2.use PrepareNFSValidIds
              b2.use SyncedFolders
              b2.use PrepareNFSSettings
            end
          end
        end
      end


      autoload :Boot, File.expand_path('../action/boot', __FILE__)
      autoload :BoxRegister, File.expand_path('../action/box_register', __FILE__)
      autoload :BoxUnregister, File.expand_path('../action/box_unregister', __FILE__)
      autoload :HandleGuestTools, File.expand_path('../action/handle_guest_tools', __FILE__)
      autoload :CheckSharedInterface, File.expand_path('../action/check_shared_interface', __FILE__)
      autoload :ClearNetworkInterfaces, File.expand_path('../action/clear_network_interfaces', __FILE__)
      autoload :ClearForwardedPorts, File.expand_path('../action/clear_forwarded_ports', __FILE__)
      autoload :Customize, File.expand_path('../action/customize', __FILE__)
      autoload :Destroy, File.expand_path('../action/destroy', __FILE__)
      autoload :DestroyUnusedNetworkInterfaces, File.expand_path('../action/destroy_unused_network_interfaces', __FILE__)
      autoload :Export, File.expand_path('../action/export', __FILE__)
      autoload :ForcedHalt, File.expand_path('../action/forced_halt', __FILE__)
      autoload :ForwardPorts, File.expand_path('../action/forward_ports', __FILE__)
      autoload :Import, File.expand_path('../action/import', __FILE__)
      autoload :Network, File.expand_path('../action/network', __FILE__)
      autoload :Package, File.expand_path('../action/package', __FILE__)
      autoload :PackageConfigFiles, File.expand_path('../action/package_config_files', __FILE__)
      autoload :PackageVagrantfile, File.expand_path('../action/package_vagrantfile', __FILE__)
      autoload :PrepareCloneSnapshot, File.expand_path('../action/prepare_clone_snapshot', __FILE__)
      autoload :PrepareForwardedPortCollisionParams, File.expand_path('../action/prepare_forwarded_port_collision_params', __FILE__)
      autoload :PrepareNFSSettings, File.expand_path('../action/prepare_nfs_settings', __FILE__)
      autoload :PrepareNFSValidIds, File.expand_path('../action/prepare_nfs_valid_ids', __FILE__)
      autoload :Resume, File.expand_path('../action/resume', __FILE__)
      autoload :SaneDefaults, File.expand_path('../action/sane_defaults',__FILE__)
      autoload :SetupPackageFiles, File.expand_path('../action/setup_package_files', __FILE__)
      autoload :SetName, File.expand_path('../action/set_name', __FILE__)
      autoload :SnapshotDelete, File.expand_path('../action/snapshot_delete', __FILE__)
      autoload :SnapshotRestore, File.expand_path('../action/snapshot_restore', __FILE__)
      autoload :SnapshotSave, File.expand_path('../action/snapshot_save', __FILE__)
      autoload :Suspend, File.expand_path('../action/suspend', __FILE__)
    end
  end
end
