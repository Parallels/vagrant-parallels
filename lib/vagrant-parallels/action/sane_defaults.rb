require 'log4r'

module VagrantPlugins
  module Parallels
    module Action
      class SaneDefaults
        def initialize(app, env)
          @logger = Log4r::Logger.new('vagrant_parallels::action::sanedefaults')
          @app = app
        end

        def call(env)
          # Set the env on an instance variable so we can access it in
          # helpers.
          @env = env

          if env[:machine].provider.pd_version_satisfies?('>= 9')
            @logger.info('Setting the power consumption mode...')
            set_power_consumption
          end

          @app.call(env)
        end

        private

        def set_power_consumption
          # Optimization of power consumption is defined by "Longer Battery Life" state.
          vm_settings = @env[:machine].provider.driver.read_settings

          old_val = vm_settings.fetch('Longer battery life') == 'on' ? true : false
          new_val = @env[:machine].provider_config.optimize_power_consumption

          if old_val == new_val
            @logger.info('Skipping power consumption method because it is already set')
          else
            mode = new_val ? 'Longer battery life' : 'Better Performance'
            @env[:ui].info I18n.t('vagrant_parallels.parallels.power_consumption.set_mode',
                                  mode: mode)
            @env[:machine].provider.driver.set_power_consumption_mode(new_val)
          end
        end
      end
    end
  end
end
