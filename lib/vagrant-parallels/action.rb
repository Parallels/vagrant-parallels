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
          b.use CheckAccessible
          # b.use CleanMachineFolder
          # b.use ClearForwardedPorts
          b.use Provision
          b.use EnvSet, :port_collision_repair => true
          # b.use PrepareForwardedPortCollisionParams
          # b.use HandleForwardedPortCollisions
          b.use PruneNFSExports
          b.use NFS
          #b.use PrepareNFSSettings
          b.use ClearSharedFolders
          b.use ShareFolders
          b.use ClearNetworkInterfaces
          # b.use Network
          # b.use ForwardPorts
          b.use SetHostname
          # b.use SaneDefaults
          b.use Boot
          b.use WaitForCommunicator
          b.use CheckGuestTools
        end
      end

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckParallels
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Call, DestroyConfirm do |env2, b3|
              if env2[:result]
                b3.use ConfigValidate
                b3.use CheckAccessible
                b3.use EnvSet, :force_halt => true
                b3.use action_halt
                b3.use UnregisterTemplate
                b3.use Destroy
              else
                b3.use MessageWillNotDestroy
              end
            end
          end
        end
      end

      # This is the action that is primarily responsible for halting
      # the virtual machine, gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckParallels
          b.use Call, Created do |env, b2|
            if env[:result]
              b2.use CheckAccessible

              b2.use Call, IsPaused do |env2, b3|
                next if !env2[:result]
                b3.use Resume
              end

              b2.use Call, GracefulHalt, :stopped, :running do |env2, b3|
                next if !env2[:result]
                b3.use ForcedHalt
              end
            else
              b2.use MessageNotCreated
            end
          end
        end
      end

      # This action packages the virtual machine into a single box file.
      def self.action_package
        Vagrant::Action::Builder.new.tap do |b|
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckParallels
          b.use ConfigValidate
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Call, IsRunning do |env2, b3|
              if !env2[:result]
                b3.use MessageNotRunning
                next
              end

              b3.use CheckAccessible
              b3.use Provision
            end
          end
        end
      end

      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckParallels
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use ConfigValidate
            b2.use action_halt
            b2.use action_start
          end
        end
      end

      # This is the action that is primarily responsible for resuming
      # suspended machines.
      def self.action_resume
        Vagrant::Action::Builder.new.tap do |b|
          Vagrant::Action::Builder.new.tap do |b|
            b.use CheckParallels
            b.use Call, Created do |env, b2|
              if env[:result]
                b2.use CheckAccessible
                b2.use EnvSet, :port_collision_repair => false
                b2.use Resume
              else
                b2.use MessageNotCreated
              end
            end
          end
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckParallels
          b.use CheckCreated
          b.use CheckAccessible
          b.use CheckRunning
          b.use SSHExec
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckParallels
          b.use CheckCreated
          b.use CheckAccessible
          b.use CheckRunning
          b.use SSHRun
        end
      end

      # This action starts a VM, assuming it is already imported and exists.
      # A precondition of this action is that the VM exists.
      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckParallels
          b.use ConfigValidate
          b.use Call, IsRunning do |env, b2|
            # If the VM is running, then our work here is done, exit
            if env[:result]
              b2.use MessageAlreadyRunning
              next
            end

            b2.use Call, IsSaved do |env2, b3|
              if env2[:result]
                # The VM is saved, so just resume it
                b3.use action_resume
                next
              end

              b3.use Call, IsPaused do |env3, b4|
                if env3[:result]
                  b4.use Resume
                  next
                end

                # The VM is not saved, so we must have to boot it up
                # like normal. Boot!
                b4.use action_boot
              end
            end
          end
        end
      end

      # This is the action that is primarily responsible for suspending
      # the virtual machine.
      def self.action_suspend
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckParallels
          b.use Call, Created do |env, b2|
            if env[:result]
              b2.use CheckAccessible
              b2.use Suspend
            else
              b2.use MessageNotCreated
            end
          end

        end
      end

      # This action brings the machine up from nothing, including importing
      # the box, configuring metadata, and booting.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckParallels
          b.use ConfigValidate
          b.use Call, Created do |env, b2|
            # If the VM is NOT created yet, then do the setup steps
            if !env[:result]
              b2.use CheckAccessible
              b2.use HandleBoxUrl
              b2.use RegisterTemplate
              b2.use Import
              b2.use UnregisterTemplate
              b2.use MatchMACAddress
            end
          end
          b.use action_start
        end
      end

      autoload :Boot, File.expand_path("../action/boot", __FILE__)
      autoload :CheckAccessible, File.expand_path("../action/check_accessible", __FILE__)
      autoload :CheckCreated, File.expand_path("../action/check_created", __FILE__)
      autoload :CheckGuestTools, File.expand_path("../action/check_guest_tools", __FILE__)
      autoload :CheckParallels, File.expand_path("../action/check_parallels", __FILE__)
      autoload :CheckRunning, File.expand_path("../action/check_running", __FILE__)
      autoload :ClearNetworkInterfaces, File.expand_path("../action/clear_network_interfaces", __FILE__)
      autoload :ClearSharedFolders, File.expand_path("../action/clear_shared_folders", __FILE__)
      autoload :Created, File.expand_path("../action/created", __FILE__)
      autoload :Destroy, File.expand_path("../action/destroy", __FILE__)
      autoload :ForcedHalt, File.expand_path("../action/forced_halt", __FILE__)
      autoload :Import, File.expand_path("../action/import", __FILE__)
      autoload :IsPaused, File.expand_path("../action/is_paused", __FILE__)
      autoload :IsRunning, File.expand_path("../action/is_running", __FILE__)
      autoload :IsSaved, File.expand_path("../action/is_saved", __FILE__)
      autoload :MatchMACAddress, File.expand_path("../action/match_mac_address", __FILE__)
      autoload :MessageAlreadyRunning, File.expand_path("../action/message_already_running", __FILE__)
      autoload :MessageNotCreated, File.expand_path("../action/message_not_created", __FILE__)
      autoload :MessageNotRunning, File.expand_path("../action/message_not_running", __FILE__)
      autoload :MessageWillNotDestroy, File.expand_path("../action/message_will_not_destroy", __FILE__)
      #autoload :PrepareNFSSettings, File.expand_path("../action/prepare_nfs_settings", __FILE__)
      autoload :PruneNFSExports, File.expand_path("../action/prune_nfs_exports", __FILE__)
      autoload :RegisterTemplate, File.expand_path("../action/register_template", __FILE__)
      autoload :Resume, File.expand_path("../action/resume", __FILE__)
      autoload :ShareFolders, File.expand_path("../action/share_folders", __FILE__)
      autoload :Suspend, File.expand_path("../action/suspend", __FILE__)
      autoload :UnregisterTemplate, File.expand_path("../action/unregister_template", __FILE__)

    end
  end
end
