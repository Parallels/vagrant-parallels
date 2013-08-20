module VagrantPlugins
  module Parallels
    module Action
      class ClearNetworkInterfaces
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # "Enable" all the adapters we setup.
          env[:ui].info I18n.t("vagrant.actions.vm.clear_network_interfaces.deleting")
          env[:machine].provider.driver.delete_adapters

          @app.call(env)
        end
      end
    end
  end
end
