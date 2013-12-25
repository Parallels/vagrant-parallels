module VagrantPlugins
  module Parallels
    module Action
      class MatchMACAddress
        def initialize(app, env)
          @app = app
        end

        def call(env)
          raise Vagrant::Errors::VMBaseMacNotSpecified if !env[:machine].config.vm.base_mac

          env[:ui].info I18n.t("vagrant_parallels.actions.vm.match_mac.matching")

          base_mac = env[:machine].config.vm.base_mac
          # Generate new base mac if the specified address is already in use
          if env[:machine].provider.driver.mac_in_use?(base_mac)
            env[:ui].info I18n.t("vagrant_parallels.actions.vm.match_mac.generate")
            env[:machine].provider.driver.set_mac_address('auto')
          else
            env[:machine].provider.driver.set_mac_address(base_mac)
          end

          @app.call(env)
        end
      end
    end
  end
end
