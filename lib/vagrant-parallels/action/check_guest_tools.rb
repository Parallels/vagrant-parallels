module VagrantPlugins
  module Parallels
    module Action
      class CheckGuestTools
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::plugins::parallels::check_guest_tools")
        end

        def call(env)
          if !env[:machine].provider_config.check_guest_tools
            @logger.info("Not checking guest tools because configuration")
            return @app.call(env)
          end

          env[:ui].output(I18n.t("vagrant_parallels.parallels.checking_guest_tools"))

          tools_version = env[:machine].provider.driver.read_guest_tools_version
          if !tools_version
            env[:ui].warn I18n.t("vagrant_parallels.actions.vm.check_guest_tools.not_detected")
          else
            pd_version = env[:machine].provider.driver.version
            if Gem::Version.new(pd_version) != Gem::Version.new(tools_version)
              env[:ui].warn(I18n.t("vagrant_parallels.actions.vm.check_guest_tools.version_mismatch",
                                   :tools_version => tools_version,
                                   :parallels_version => pd_version))
            end
          end

          # Continue
          @app.call(env)
        end

      end
    end
  end
end
