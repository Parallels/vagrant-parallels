module VagrantPlugins
  module Parallels
    module Action
      class ClearNetworkInterfaces
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Delete all disabled network adapters
          env[:ui].info I18n.t('vagrant.actions.vm.clear_network_interfaces.deleting')
          env[:machine].provider.driver.delete_disabled_adapters

          @app.call(env)
        end
      end
    end
  end
end
