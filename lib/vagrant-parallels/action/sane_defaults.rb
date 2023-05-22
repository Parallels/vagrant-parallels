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

          @env[:ui].info I18n.t('vagrant_parallels.actions.vm.sane_defaults.setting')

          default_settings.each do |setting, value|
            @env[:machine].provider.driver.execute_prlctl(
              'set', @env[:machine].id, "--#{setting.to_s.gsub('_','-')}", value)
          end

          @app.call(env)
        end

        private

        def default_settings
          # Options defined below are not supported for `*.macvm` VMs
          return {} if Util::Common::is_macvm(@env[:machine])

          {
            tools_autoupdate: 'no',
            on_shutdown: 'close',
            on_window_close: 'keep-running',
            auto_share_camera: 'off',
            smart_guard: 'off',
            longer_battery_life: 'on',
            shared_cloud: 'off',
            shared_profile: 'off',
            smart_mount: 'off',
            sh_app_guest_to_host: 'off',
            sh_app_host_to_guest: 'off',
            startup_view: 'headless',
            time_sync: 'on',
            disable_timezone_sync: 'on',
            shf_host_defined: 'off'
          }
        end
      end
    end
  end
end
