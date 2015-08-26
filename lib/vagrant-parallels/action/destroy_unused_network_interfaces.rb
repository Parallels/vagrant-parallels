require 'log4r'

module VagrantPlugins
  module Parallels
    module Action
      class DestroyUnusedNetworkInterfaces
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].provider_config.destroy_unused_network_interfaces
            env[:ui].info I18n.t('vagrant.actions.vm.destroy_network.destroying')
            env[:machine].provider.driver.delete_unused_host_only_networks
          end

          @app.call(env)
        end
      end
    end
  end
end
