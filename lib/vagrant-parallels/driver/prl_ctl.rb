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
          status = read_status(@uuid)
          return nil unless status
          read_status.fetch('status')
        end

        # Returns a list of all UUIDs of virtual machines currently
        # known by Parallels.
        #
        # @return [Array<String>]
        def read_vms
          list = read_status
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

        def import(box_name)
          last = 0
          name = suggest_vm_name

          execute("clone", box_name, '--name', name) do |type, data|
            lines = data.split("\r")
            # The progress of the import will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3})%/
              current = $1.to_i
              if current > last
                last = current
                yield current if block_given?
              end
            end
          end

          name
        end

        def register(pvm_file)
          execute("register", pvm_file)
        end

        private

          def read_status(id)
            params = ['list']
            params << id if id
            params << '--all'
            params << '--json'
            output = execute(params)
            return nil if output =~ /^VM is not found$/
            JSON.parse(output)
          end

          def suggest_vm_name
            Time.now.to_a.slice(0..5).reverse.join('')
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
