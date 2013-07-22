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

        # Returns the current state of this VM.
        #
        # @return [Symbol]
        def read_state
          output = execute("list", @uuid, "--all", "--json")

          if output =~ /^VM is not found$/
            return :inaccessible
          elsif state = JSON.parse(output)
            return state.first.fetch('status')
          end

          nil
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

        # Verifies that the driver is ready to accept work.
        #
        # This should raise a VagrantError if things are not ready.
        def verify!
          execute('--version')
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
