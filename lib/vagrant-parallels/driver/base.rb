require 'log4r'

require 'vagrant/util/busy'
require 'vagrant/util/network_ip'
require 'vagrant/util/platform'
require 'vagrant/util/retryable'
require 'vagrant/util/subprocess'

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
          @logger = Log4r::Logger.new("vagrant::provider::parallels::base")

          # This flag is used to keep track of interrupted state (SIGINT)
          @interrupted = false

          # Set the list of required CLI utils
          @cli_paths = {
            :prlctl        => "prlctl",
            :prlsrvctl     => "prlsrvctl",
            :prl_disk_tool => "prl_disk_tool",
            :ifconfig      => "ifconfig"
          }

          @cli_paths.each do |name, path|
            @logger.info("CLI utility '#{name}' path: #{path}")
          end
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

        # Execute a raw command straight through to 'prlctl' utility
        #
        # Accepts a :prlsrvctl as a first element of command if the command
        # should be executed through to 'prlsrvctl' utility
        #
        # Accepts a :retryable => true option if the command should be retried
        # upon failure.
        #
        # Raises a prlctl error if it fails.
        #
        # @param [Array] command Command to execute.
        def execute_command(command)
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

        # Returns the guest tools version that is installed on this VM.
        #
        # @return [String]
        def read_guest_tools_version
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
        # @return [Hash<String, String>] Adapter => MAC address
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

        # Returns a list of all registered
        # virtual machines and templates.
        #
        # @return [Hash]
        def read_vms
        end

        # Registers the virtual machine
        #
        # @param [String] pvm_file Path to the machine image (*.pvm)
        # @param [Boolean] regen_src_uuid Regenerate SourceVmUuid to avoid
        # SMBIOS UUID collision
        def register(pvm_file, regen_src_uuid)
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

        # Execute the given subcommand for PrlCtl and return the output.
        def execute(*command, &block)
          # Get the options hash if it exists
          opts = {}
          opts = command.pop if command.last.is_a?(Hash)

          tries = opts[:retryable] ? 3 : 0

          # Variable to store our execution result
          r = nil

          retryable(:on => VagrantPlugins::Parallels::Errors::PrlCtlError, :tries => tries, :sleep => 1) do
            # If there is an error with PrlCtl, this gets set to true
            errored = false

            # Execute the command
            r = raw(*command, &block)

            # If the command was a failure, then raise an exception that is
            # nicely handled by Vagrant.
            if r.exit_code != 0
              if @interrupted
                @logger.info("Exit code != 0, but interrupted. Ignoring.")
              else
                errored = true
              end
            end

            # If there was an error running prlctl, show the error and the
            # output.
            if errored
              raise VagrantPlugins::Parallels::Errors::PrlCtlError,
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
          command << { :notify => [:stdout, :stderr] }

          # Get the utility from the first argument:
          # 'prlctl' by default
          util = @cli_paths.has_key?(command.first) ? command.delete_at(0) : :prlctl
          cli = @cli_paths[util]

          Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute(cli, *command, &block)
          end
        end
      end
    end
  end
end
