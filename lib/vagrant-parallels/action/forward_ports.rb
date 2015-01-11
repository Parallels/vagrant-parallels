module VagrantPlugins
  module Parallels
    module Action
      class ForwardPorts
        include Util::CompileForwardedPorts

        def initialize(app, env)
          @app = app
        end

        #--------------------------------------------------------------
        # Execution
        #--------------------------------------------------------------
        def call(env)
          # Port Forwarding feature is available only with PD >= 10
          if !env[:machine].provider.pd_version_satisfies?('>= 10')
            return @app.call(env)
          end

          @env = env

          # Get the ports we're forwarding
          env[:forwarded_ports] ||= compile_forwarded_ports(env[:machine].config, env[:machine])
          env[:ui].output(I18n.t('vagrant.actions.vm.forward_ports.forwarding'))
          forward_ports

          @app.call(env)
        end

        def forward_ports
          ports = []

          @env[:forwarded_ports].each do |fp|
            message_attributes = {
              guest_port: fp.guest_port,
              host_port: fp.host_port
            }

            # Assuming the only reason to establish port forwarding is
            # because the VM is using Shared networking. Host-only and
            # bridged networking don't require port-forwarding and establishing
            # forwarded ports on these attachment types has uncertain behaviour.
            @env[:ui].detail(I18n.t("vagrant_parallels.actions.vm.forward_ports.forwarding_entry",
                                    message_attributes))

            # Add the options to the ports array to send to the driver later
            ports << {
              guestport: fp.guest_port,
              hostport:  fp.host_port,
              name:      get_unique_name(fp.id),
              protocol:  fp.protocol
            }
          end

          if !ports.empty?
            # We only need to forward ports if there are any to forward
            @env[:machine].provider.driver.forward_ports(ports)
          end
        end

        private

        def get_unique_name(id)
          all_rules = @env[:machine].provider.driver.read_forwarded_ports(true)
          names_in_use = all_rules.collect { |r| r[:rule_name] }

          # Append random suffix to get unique rule name
          while names_in_use.include?(id)
            suffix = (0...4).map { ('a'..'z').to_a[rand(26)] }.join
            id = "#{id}_#{suffix}"
          end

          id
        end
      end
    end
  end
end
