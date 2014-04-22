module VagrantPlugins
  module Parallels
    module Action
      class SetPowerConsumption
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::plugins::parallels::power_consumption")
          @app = app
        end

        def call(env)
          # Optimization of power consumption is defined by "Longer Battery Life" state.
          vm_settings = env[:machine].provider.driver.read_settings

          old_val = vm_settings.fetch("Longer battery life") == "on" ? true : false
          new_val = env[:machine].provider_config.optimize_power_consumption

          if old_val == new_val
            @logger.info("Skipping power consumption method because it is already set")
            return @app.call(env)
          end

          mode = new_val ? "Longer battery life" : "Better Performance"

          env[:ui].info I18n.t(
                          "vagrant_parallels.parallels.power_consumption.set_mode",
                          mode: mode)
          env[:machine].provider.driver.set_power_consumption_mode(new_val)

          @app.call(env)
        end
      end
    end
  end
end
