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

          settings = default_settings

          @app.call(env) if settings.empty?
          @env[:ui].info I18n.t('vagrant_parallels.actions.vm.sane_defaults.setting')

          default_settings.each do |setting, value|
            @env[:machine].provider.driver.execute_prlctl(
              'set', @env[:machine].id, "--#{setting.to_s.gsub('_','-')}", value)
          end

          @app.call(env)
        end

        private

        def default_settings
          settings = {}

          return settings if @env[:machine].provider.pd_version_satisfies?('< 9')
          settings.merge!(
            startup_view: 'same',
            on_shutdown: 'close',
            on_window_close: 'keep-running',
            auto_share_camera: 'off',
            smart_guard: 'off',
            longer_battery_life: 'on'
          )

          # Check the legacy option
          if !@env[:machine].provider_config.optimize_power_consumption
            settings[:longer_battery_life] = 'off'
          end

          return settings  if @env[:machine].provider.pd_version_satisfies?('< 10.1.2')
          settings.merge!(
            shared_cloud: 'off',
            shared_profile: 'off',
            smart_mount: 'off',
            sh_app_guest_to_host: 'off',
            sh_app_host_to_guest: 'off',
            time_sync: 'off'
          )

          return settings if @env[:machine].provider.pd_version_satisfies?('< 11')
          settings.merge!(
            startup_view: 'headless',
            time_sync: 'on',
            disable_timezone_sync: 'on',
            shf_host_defined: 'off'
          )

          settings
        end
      end
    end
  end
end
