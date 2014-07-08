module VagrantPlugins
  module Parallels
    module Action
      class ClearForwardedPorts
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Port Forwarding feature is available only with PD >= 10
          if !env[:machine].provider.pd_version_satisfies?('>= 10')
            return @app.call(env)
          end

          if !env[:machine].provider.driver.read_forwarded_ports.empty?
            env[:ui].info I18n.t('vagrant.actions.vm.clear_forward_ports.deleting')
            env[:machine].provider.driver.clear_forwarded_ports
          end

          @app.call(env)
        end
      end
    end
  end
end
