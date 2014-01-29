module VagrantPlugins
  module Parallels
    module Action
      class CheckGuestTools
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].output(I18n.t("vagrant_parallels.parallels.checking_guest_tools"))

          tools_version = env[:machine].provider.driver.read_guest_tools_version
          if !tools_version
            env[:ui].warn I18n.t("vagrant_parallels.actions.vm.check_guest_tools.not_detected")
          else
            pd_version = env[:machine].provider.driver.version
            unless pd_version.start_with? tools_version
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
