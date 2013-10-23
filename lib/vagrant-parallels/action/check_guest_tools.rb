module VagrantPlugins
  module Parallels
    module Action
      class CheckGuestTools
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Use the raw interface for now, while the virtualbox gem
          # doesn't support guest properties (due to cross platform issues)
          tools_version = env[:machine].provider.driver.read_guest_tools_version
          if !tools_version
            env[:ui].warn I18n.t("vagrant.actions.vm.check_guest_tools.not_detected")
          else
            env[:machine].provider.driver.verify! =~ /^[\w\s]+ ([\d.]+)$/
            os_version = $1
            unless os_version.start_with? tools_version
              env[:ui].warn(I18n.t("vagrant_parallels.actions.vm.check_guest_tools.version_mismatch",
                                   tools_version: tools_version,
                                   parallels_version: os_version))
            end
          end

          # Continue
          @app.call(env)
        end

      end
    end
  end
end
