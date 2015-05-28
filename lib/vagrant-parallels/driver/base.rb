require 'log4r'

require 'vagrant/util/busy'
require 'vagrant/util/network_ip'
require 'vagrant/util/platform'
require 'vagrant/util/subprocess'
require 'vagrant/util/which'

module VagrantPlugins
  module Parallels
    module Driver
      # Base class for all Parallels drivers.
      #
      # This class provides useful tools for things such as executing
      # PrlCtl and handling SIGINTs and so on.
      class Base
        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable
        include Vagrant::Util::NetworkIP

        def initialize
          @logger = Log4r::Logger.new('vagrant_parallels::driver::base')

          # This flag is used to keep track of interrupted state (SIGINT)
          @interrupted = false

          @prlctl_path    = util_path('prlctl')
          @prlsrvctl_path = util_path('prlsrvctl')
          @prldisktool_path = util_path('prl_disk_tool')

          if !@prlctl_path
            # This means that Parallels Desktop was not found, so we raise this
            # error here.
            raise VagrantPlugins::Parallels::Errors::ParallelsNotDetected
          end

          @logger.info("prlctl path: #{@prlctl_path}")
          @logger.info("prlsrvctl path: #{@prlsrvctl_path}")
        end

        # Clears the shared folders that have been set on the virtual machine.
        def clear_shared_folders
        end

        # Compacts all disk drives of virtual machine
        def compact
        end

        # Creates a host only network with the given options.
        #
        # @param [Hash] options Options to create the host only network.
        # @return [Hash] The details of the host only network, including
        #   keys `:name`, `:ip`, `:netmask` and `:dhcp`
        def create_host_only_network(options)
        end

        # Deletes the virtual machine references by this driver.
        def delete
        end

        # Deletes all disabled network adapters from the VM configuration
        def delete_disabled_adapters
        end

        # Deletes any host only networks that aren't being used for anything.
        def delete_unused_host_only_networks
        end

        # Disables requiring password on such operations as creating, adding,
        # removing or cloning the virtual machine.
        #
        def disable_password_restrictions
        end

        # Enables network adapters on the VM.
        #
        # The format of each adapter specification should be like so:
        #
        # {
        #   :type     => :hostonly,
        #   :hostonly => "vagrant-vnet0",
        #   :name     => "vnic2",
        #   :nic_type => "virtio"
        # }
        #
        # This must support setting up both host only and bridged networks.
        #
        # @param [Array<Hash>] adapters Array of adapters to enable.
        def enable_adapters(adapters)
        end

        # Exports the virtual machine to the given path.
        #
        # @param [String] path Path to the OVF file.
        # @yield [progress] Yields the block with the progress of the export.
        def export(path)
        end

        # Halts the virtual machine (pulls the plug).
        def halt(force)
        end

        # Imports the VM by cloning from registered template.
        #
        # @param [String] template_uuid Registered template UUID.
        # @return [String] UUID of the imported VM.
        def import(template_uuid)
        end

        # Parses given block (JSON string) to object
        def json(default=nil)
          data = yield
          JSON.parse(data) rescue default
        end

        # Returns the maximum number of network adapters.
        def max_network_adapters
          16
        end

        # Returns a list of bridged interfaces.
        #
        # @return [Hash]
        def read_bridged_interfaces
        end

        # Returns the state of guest tools that is installed on this VM.
        # Can be any of:
        # * "installed"
        # * "not_installed"
        # * "possibly_installed"
        # * "outdated"
        #
        # @return [String]
        def read_guest_tools_state
        end

        # Returns path to the Parallels Tools ISO file.
        #
        # @param [String] guest_os Guest os type: "linux", "darwin" or "windows"
        # @return [String] Path to the ISO.
        def read_guest_tools_iso_path(guest_os)
        end

        # Returns a list of available host only interfaces.
        #
        # @return [Hash]
        def read_host_only_interfaces
        end

        # Returns the MAC address of the first network interface.
        #
        # @return [String]
        def read_mac_address
        end

        # Returns the network interface card MAC addresses
        #
        # @return [Hash<Integer, String>] Adapter => MAC address
        def read_mac_addresses
        end

        # Returns a list of network interfaces of the VM.
        #
        # @return [Hash]
        def read_network_interfaces
        end

        # Returns info about shared network interface.
        #
        # @return [Hash]
        def read_shared_interface
        end

        # Returns a list of shared folders in format:
        # { id => hostpath, ... }
        #
        # @return [Hash]
        def read_shared_folders
        end

        # Returns the current state of this VM.
        #
        # @return [Symbol]
        def read_state
        end

        # Returns a value of specified VM option. Raises an exception if value
        # is not available
        #
        # @param [String] option Name of option (See all: `prlctl list -L`)
        # @param [String] uuid Virtual machine UUID
        # @return [String]
        def read_vm_option(option, uuid=@uuid)
        end

        # Returns a list of all registered
        # virtual machines and templates.
        #
        # @return [Hash]
        def read_vms
        end

        # Regenerates 'SourceVmUuid' to avoid SMBIOS UUID collision [GH-113]
        #
        def regenerate_src_uuid
        end

        # Registers the virtual machine
        #
        # @param [String] pvm_file Path to the machine image (*.pvm)
        def register(pvm_file)
        end

        # Resumes the virtual machine.
        #
        def resume
        end

        # Sets the MAC address of the first network adapter.
        #
        # @param [String] mac MAC address without any spaces/hyphens.
        def set_mac_address(mac)
        end

        # Sets the name of the virtual machine.
        #
        # @param [String] name New VM name.
        def set_name(name)
        end

        # Sets Power Consumption method.
        #
        # @param [Boolean] optimized Use "Longer Battery Life"
        # instead "Better Performance"
        def set_power_consumption_mode(optimized)
        end

        # Share a set of folders on this VM.
        #
        # @param [Array<Hash>] folders
        def share_folders(folders)
        end

        # Reads the SSH port of this VM.
        #
        # @param [Integer] expected Expected guest port of SSH.
        def ssh_port(expected)
        end

        # Starts the virtual machine.
        #
        def start
        end

        # Suspend the virtual machine.
        def suspend
        end

        # Unshare folders.
        def unshare_folders(names)
        end

        # Checks if a VM with the given UUID exists.
        #
        # @return [Boolean]
        def vm_exists?(uuid)
        end

        # Wraps 'execute' and returns the output of given 'prlctl' subcommand.
        def execute_prlctl(*command, &block)
          execute(@prlctl_path, *command, &block)
        end

        #Wraps 'execute' and returns the output of given 'prlsrvctl' subcommand.
        def execute_prlsrvctl(*command, &block)
          execute(@prlsrvctl_path, *command, &block)
        end

        # Execute the given command and return the output.
        def execute(*command, &block)
          r = raw(*command, &block)

          # If the command was a failure, then raise an exception that is
          # nicely handled by Vagrant.
          if r.exit_code != 0
            if @interrupted
              @logger.info("Exit code != 0, but interrupted. Ignoring.")
            else
              # If there was an error running command, show the error and the
              # output.
              raise VagrantPlugins::Parallels::Errors::ExecutionError,
                :command => command.inspect,
                :stderr  => r.stderr
            end
          end
          r.stdout
        end

        # Executes a command and returns the raw result object.
        def raw(*command, &block)
          int_callback = lambda do
            @interrupted = true

            # We have to execute this in a thread due to trap contexts
            # and locks.
            Thread.new { @logger.info("Interrupted.") }
          end

          # Append in the options for subprocess
          command << {notify: [:stdout, :stderr]}

          Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute(*command, &block)
          end
        end

        private

        def util_path(bin)
          path = Vagrant::Util::Which.which(bin)
          return path if path

          ['/usr/local/bin', '/usr/bin'].each do |folder|
            path = File.join(folder, bin)
            return path if File.file?(path)
          end
        end

      end
    end
  end
end
