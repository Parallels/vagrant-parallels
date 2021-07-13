module VagrantPlugins
  module Parallels
    module Action
      class ForwardPorts
        include VagrantPlugins::Parallels::Util::CompileForwardedPorts
        @@lock = Mutex.new

        def initialize(app, env)
          @app = app
        end

        #--------------------------------------------------------------
        # Execution
        #--------------------------------------------------------------
        def call(env)
          @env = env

          # Get the ports we're forwarding
          env[:forwarded_ports] ||= compile_forwarded_ports(env[:machine].config)

          # Exit if there are no ports to forward
          return @app.call(env) if env[:forwarded_ports].empty?

          # Acquire both of class- and process-level locks so that we don't
          # forward ports simultaneousely with someone else.
          @@lock.synchronize do
            begin
              env[:machine].env.lock('forward_ports') do
                env[:ui].output(I18n.t('vagrant.actions.vm.forward_ports.forwarding'))
                forward_ports
              end
            rescue Errors::EnvironmentLockedError
              sleep 1
              retry
            end
          end

          @app.call(env)
        end

        def forward_ports
          all_rules = @env[:machine].provider.driver.read_forwarded_ports(true)
          names_in_use = all_rules.collect { |r| r[:name] }
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
            @env[:ui].detail(I18n.t('vagrant_parallels.actions.vm.forward_ports.forwarding_entry',
                                    **message_attributes))

            # In Parallels Desktop the scope port forwarding rules is global,
            # so we have to keep their names unique.
            unique_id = fp.id
            # Append random suffix to get the unique rule name
            while names_in_use.include?(unique_id)
              suffix = (0...4).map { ('a'..'z').to_a[rand(26)] }.join
              unique_id = "#{fp.id}_#{suffix}"
            end
            # Mark this rule name as in use
            names_in_use << unique_id

            # Add the options to the ports array to send to the driver later
            ports << {
              guestport: fp.guest_port,
              hostport:  fp.host_port,
              name:      unique_id,
              protocol:  fp.protocol
            }
          end

          if !ports.empty?
            # We only need to forward ports if there are any to forward
            @env[:machine].provider.driver.forward_ports(ports)
          end
        end
      end
    end
  end
end
