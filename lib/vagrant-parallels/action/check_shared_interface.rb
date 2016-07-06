module VagrantPlugins
  module Parallels
    module Action
      class CheckSharedInterface
        def initialize(app, env)
          @app = app
        end

        def call(env)
          shared_iface = env[:machine].provider.driver.read_shared_interface

          # Shared interface is connected. Just exit
          return @app.call(env) if shared_iface[:status] == 'Up'

          # Since PD 11.2.1 Vagrant can fix this automatically
          if !env[:machine].provider.pd_version_satisfies?('>= 11.2.1')
            raise Errors::SharedInterfaceDisconnected
          end

          env[:ui].info I18n.t('vagrant_parallels.actions.vm.check_shared_interface.connecting')
          iface_name = env[:machine].provider.driver.read_shared_network_id
          env[:machine].provider.driver.connect_network_interface(iface_name)

          @app.call(env)
        end
      end
    end
  end
end
