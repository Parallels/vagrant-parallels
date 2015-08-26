require 'log4r'
require 'vagrant'

module VagrantPlugins
  module Parallels
    class Provider < Vagrant.plugin('2', :provider)
      attr_reader :driver

      def self.usable?(raise_error=false)
        if !Vagrant::Util::Platform.darwin?
          raise Errors::MacOSXRequired
        end

        # Instantiate the driver, which will determine the Parallels Desktop
        # version and all that, which checks for Parallels Desktop being present
        Driver::Meta.new
        true
      rescue Errors::VagrantParallelsError
        raise if raise_error
        return false
      end

      def initialize(machine)
        @logger = Log4r::Logger.new('vagrant::provider::parallels')
        @machine = machine

        # This method will load in our driver, so we call it now to
        # initialize it.
        machine_id_changed
      end

      # @see Vagrant::Plugin::V2::Provider#action
      def action(name)
        # Attempt to get the action method from the Action class if it
        # exists, otherwise return nil to show that we don't support the
        # given action.
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      # If the machine ID changed, then we need to rebuild our underlying
      # driver.
      def machine_id_changed
        id = @machine.id

        begin
          @logger.debug("Instantiating the driver for machine ID: #{@machine.id.inspect}")
          @driver = VagrantPlugins::Parallels::Driver::Meta.new(id)
        rescue VagrantPlugins::Parallels::Driver::Meta::VMNotFound
          # The virtual machine doesn't exist, so we probably have a stale
          # ID. Just clear the id out of the machine and reload it.
          @logger.debug('VM not found! Clearing saved machine ID and reloading.')
          id = nil
          retry
        end
      end

      # Returns the SSH info for accessing the Parallels VM.
      def ssh_info
        # If the VM is not running that we can't possibly SSH into it
        return nil if state.id != :running

        detected_ip = @driver.ssh_ip

        # If ip couldn't be detected then we cannot possibly SSH into it,
        # and should return nil too.
        return nil if !detected_ip

        # Return ip from running machine, use ip from config if available
        {
          host: detected_ip,
          port: @driver.ssh_port(@machine.config.ssh.guest_port)
        }
      end

      # Return the state of Parallels virtual machine by actually
      # querying PrlCtl.
      #
      # @return [Symbol]
      def state
        # Determine the ID of the state here.
        state_id = nil
        state_id = :not_created if !@driver.uuid
        state_id = @driver.read_state if !state_id
        state_id = :unknown if !state_id

        # Translate into short/long descriptions
        short = state_id.to_s.gsub('_', ' ')
        long  = I18n.t("vagrant_parallels.commands.status.#{state_id}")

        # If machine is not created, then specify the special ID flag
        if state_id == :not_created
          state_id = Vagrant::MachineState::NOT_CREATED_ID
        end

        # Return the state
        Vagrant::MachineState.new(state_id, short, long)
      end

      # Determines if the installed Parallels Desktop version is
      # satisfied by the given constraint or group of constraints.
      #
      # @return [Boolean]
      def pd_version_satisfies?(*constraints)
        pd_version = Gem::Version.new(@driver.version)
        Gem::Requirement.new(*constraints).satisfied_by?(pd_version)
      end

      # Returns a human-friendly string version of this provider which
      # includes the machine's ID that this provider represents, if it
      # has one.
      #
      # @return [String]
      def to_s
        id = @machine.id ? @machine.id : 'new VM'
        "Parallels (#{id})"
      end
    end
  end
end
