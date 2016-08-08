module VagrantPlugins
  module Parallels
    module Action
      class ClearForwardedPorts
        def initialize(app, env)
          @app = app
        end

        def call(env)
          ports = env[:machine].provider.driver.read_forwarded_ports
          if !ports.empty?
            env[:ui].info I18n.t('vagrant.actions.vm.clear_forward_ports.deleting')
            env[:machine].provider.driver.clear_forwarded_ports(ports)
          end

          @app.call(env)
        end
      end
    end
  end
end
