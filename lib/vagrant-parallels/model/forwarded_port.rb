module VagrantPlugins
  module Parallels
    module Model
      # Represents a single forwarded port for Parallels Desktop. This has
      # various helpers and defaults for a forwarded port.
      class ForwardedPort
        # If true, the forwarded port should be auto-corrected.
        #
        # @return [Boolean]
        attr_reader :auto_correct

        # The unique ID for the forwarded port.
        #
        # @return [String]
        attr_reader :id

        # The protocol to forward.
        #
        # @return [String]
        attr_reader :protocol

        # The port on the guest to be exposed on the host.
        #
        # @return [Integer]
        attr_reader :guest_port

        # The port on the host used to access the port on the guest.
        #
        # @return [Integer]
        attr_reader :host_port

        # The ip of the guest to be used for the port.
        #
        # @return [String]
        attr_reader :guest_ip

        # The ip of the host used to access the port.
        #
        # @return [String]
        attr_reader :host_ip

        def initialize(id, host_port, guest_port, host_ip, guest_ip, **options)
          @id         = id
          @guest_port = guest_port
          @guest_ip   = guest_ip
          @host_port  = host_port
          @host_ip    = host_ip

          options ||= {}
          @auto_correct = false
          @auto_correct = options[:auto_correct] if options.key?(:auto_correct)
          @protocol = options[:protocol] || 'tcp'
        end

        # This corrects the host port and changes it to the given new port.
        #
        # @param [Integer] new_port The new port
        def correct_host_port(new_port)
          @host_port = new_port
        end
      end
    end
  end
end
