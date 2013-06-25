require "log4r"
require "vagrant"

module VagrantPlugins
  module Parallels
    class Provider < Vagrant.plugin("2", :provider)
      attr_reader :driver

      def initialize(machine)
        @logger = Log4r::Logger.new("vagrant::provider::parallels")
        @machine = machine
        @driver = Parallels::Driver::PrlCtl.new(machine.id)
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

      # Returns the SSH info for accessing the Parallels VM.
      def ssh_info
        # If the VM is not created then we cannot possibly SSH into it, so
        # we return nil.
        return nil if state.id == :not_created

        # Return what we know. The host is always "127.0.0.1" because
        # Parallels VMs are always local. The port we try to discover
        # by reading the forwarded ports.
        return {
          :host => "127.0.0.1",
          :port => @driver.ssh_port(@machine.config.ssh.guest_port)
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
        short = state_id.to_s.gsub("_", " ")
        long  = I18n.t("vagrant.commands.status.#{state_id}")

        # Return the state
        Vagrant::MachineState.new(state_id, short, long)
      end

      # Returns a human-friendly string version of this provider which
      # includes the machine's ID that this provider represents, if it
      # has one.
      #
      # @return [String]
      def to_s
        id = @machine.id ? @machine.id : "new VM"
        "Parallels (#{id})"
      end
    end
  end
end