require 'log4r'
require 'json'

require 'vagrant/util/busy'
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
      class PrlCtl
        # Include this so we can use `Subprocess` more easily.
        include Vagrant::Util::Retryable

        attr_reader :uuid

        def initialize(uuid)
          @logger = Log4r::Logger.new("vagrant::provider::parallels::prlctl")

          # This flag is used to keep track of interrupted state (SIGINT)
          @interrupted = false

          # Store machine id
          @uuid = uuid

          # Set the path to prlctl
          @manager_path = "prlctl"

          @logger.info("Parallels path: #{@manager_path}")
        end

        # Clears the forwarded ports that have been set on the virtual machine.
        def clear_forwarded_ports
        end

        # Clears the shared folders that have been set on the virtual machine.
        def clear_shared_folders
        end

        # Creates a DHCP server for a host only network.
        #
        # @param [String] network Name of the host-only network.
        # @param [Hash] options Options for the DHCP server.
        def create_dhcp_server(network, options)
        end

        # Creates a host only network with the given options.
        #
        # @param [Hash] options Options to create the host only network.
        # @return [Hash] The details of the host only network, including
        #   keys `:name`, `:ip`, and `:netmask`
        def create_host_only_network(options)
        end

        # Deletes the virtual machine references by this driver.
        def delete
        end

        # Deletes any host only networks that aren't being used for anything.
        def delete_unused_host_only_networks
        end

        # Discards any saved state associated with this VM.
        def discard_saved_state
        end

        # Enables network adapters on the VM.
        #
        # The format of each adapter specification should be like so:
        #
        # {
        #   :type     => :hostonly,
        #   :hostonly => "vboxnet0",
        #   :mac_address => "tubes"
        # }
        #
        # This must support setting up both host only and bridged networks.
        #
        # @param [Array<Hash>] adapters Array of adapters to enable.
        def enable_adapters(adapters)
        end

        # Execute a raw command straight through to PrlCtl.
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

        # Forwards a set of ports for a VM.
        #
        # This will not affect any previously set forwarded ports,
        # so be sure to delete those if you need to.
        #
        # The format of each port hash should be the following:
        #
        #     {
        #       :name => "foo",
        #       :hostport => 8500,
        #       :guestport => 80,
        #       :adapter => 1,
        #       :protocol => "tcp"
        #     }
        #
        # Note that "adapter" and "protocol" are optional and will default
        # to 1 and "tcp" respectively.
        #
        # @param [Array<Hash>] ports An array of ports to set. See documentation
        #   for more information on the format.
        def forward_ports(ports)
        end

        # Halts the virtual machine (pulls the plug).
        def halt
        end

        # Imports the VM from an OVF file.
        #
        # @param [String] ovf Path to the OVF file.
        # @return [String] UUID of the imported VM.
        def import(name, path)
          begin
            require 'debugger'; debugger
            last = 0
            # Register template
            execute("register", path)
            # Get last registered template
            execute("create", "vagrant_parallels2", "--ostemplate", name) do |type, data|
              if data.include?("progress")
                # The progress of the import will be in the last line. Do a greedy
                # regular expression to find what we're looking for.
                lines = data.split("\n")
                if lines.last =~ /.+(\d{2})%/
                  current = $1.to_i
                  if current > last
                    last = current
                    yield current if block_given?
                  end
                end
              end
            end
          ensure
            # Unregister template
            execute("unregister", name)
          end
        end

        # Returns a list of forwarded ports for a VM.
        #
        # @param [String] uuid UUID of the VM to read from, or `nil` if this
        #   VM.
        # @param [Boolean] active_only If true, only VMs that are running will
        #   be checked.
        # @return [Array<Array>]
        def read_forwarded_ports(uuid=nil, active_only=false)
        end

        # Returns a list of bridged interfaces.
        #
        # @return [Hash]
        def read_bridged_interfaces
        end

        # Returns the guest additions version that is installed on this VM.
        #
        # @return [String]
        def read_guest_additions_version
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

        # Returns the folder where Parallels places it's VMs.
        #
        # @return [String]
        def read_machine_folder
        end

        # Returns a list of network interfaces of the VM.
        #
        # @return [Hash]
        def read_network_interfaces
        end

        # Returns the current state of this VM.
        #
        # @return [Symbol]
        def read_state
          output = execute("list", @uuid, "--all", "--json")
          
          if output =~ /^VM is not found$/
            return :inaccessible
          elsif state = JSON.parse(output)se
            return state.first.fetch('status')
          end

          nil
        end

        # Returns a list of all forwarded ports in use by active
        # virtual machines.
        #
        # @return [Array]
        def read_used_ports
        end

        # Returns a list of all UUIDs of virtual machines currently
        # known by Parallels.
        #
        # @return [Array<String>]
        def read_vms
          list = JSON.parse(execute("list", "--all", "--json"))
          list.map do |item|
            item.fetch('uuid')
          end
        end

        # Returns a list of all UUIDs of virtual machines currently
        # known by Parallels.
        #
        # @return [Array<String>]
        def read_templates
          stdout = execute("list", "--templates", "--json")
          list = JSON.parse(stdout)
          list.map do |item|
            item.fetch('uuid')
          end
        end

        # Sets the MAC address of the first network adapter.
        #
        # @param [String] mac MAC address without any spaces/hyphens.
        def set_mac_address(mac)
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
        # @param [String] mode Mode to boot the VM. Either "headless"
        #   or "gui"
        def start(mode)
        end

        # Suspend the virtual machine.
        def suspend
        end

        # Verifies that the driver is ready to accept work.
        #
        # This should raise a VagrantError if things are not ready.
        def verify!
          execute('--version')
        end

        # Verifies that an image can be imported properly.
        #
        # @param [String] path Path to an OVF file.
        # @return [Boolean]
        def verify_image(path)
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

          tries = 0
          tries = 3 if opts[:retryable]

          # Variable to store our execution result
          r = nil

          # If there is an error with PrlCtl, this gets set to true
          errored = false

          retryable(:on => VagrantPlugins::Parallels::Errors::ParallelsError, :tries => tries, :sleep => 1) do
            # Execute the command
            r = raw(*command, &block)

            # If the command was a failure, then raise an exception that is
            # nicely handled by Vagrant.
            if r.exit_code != 0
              if @interrupted
                @logger.info("Exit code != 0, but interrupted. Ignoring.")
              elsif r.exit_code == 126
                # This exit code happens if PrlCtl is on the PATH,
                # but another executable it tries to execute is missing.
                # This is usually indicative of a corrupted Parallels install.
                raise VagrantPlugins::Parallels::Errors::ParallelsErrorNotFoundError
              else
                errored = true
              end
            else
              if r.stderr =~ /failed to open \/dev\/prlctl/i
                # This catches an error message that only shows when kernel
                # drivers aren't properly installed.
                @logger.error("Error message about unable to open prlctl")
                raise VagrantPlugins::Parallels::Errors::ParallelsErrorKernelModuleNotLoaded
              end

              if r.stderr =~ /Invalid usage/
                @logger.info("PrlCtl error text found, assuming error.")
                errored = true
              end
            end
          end

          # If there was an error running PrlCtl, show the error and the
          # output.
          if errored
            raise VagrantPlugins::Parallels::Errors::ParallelsError,
              :command => command.inspect,
              :stderr  => r.stderr
          end

          r.stdout
        end

        # Executes a command and returns the raw result object.
        def raw(*command, &block)
          int_callback = lambda do
            @interrupted = true
            @logger.info("Interrupted.")
          end

          # Append in the options for subprocess
          command << { :notify => [:stdout, :stderr] }

          Vagrant::Util::Busy.busy(int_callback) do
            Vagrant::Util::Subprocess.execute(@manager_path, *command, &block)
          end
        end
      end
    end
  end
end
