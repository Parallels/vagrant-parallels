module VagrantPlugins
  module Parallels
    module Action
      class CheckGuestAdditions
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Use the raw interface for now, while the virtualbox gem
          # doesn't support guest properties (due to cross platform issues)
          guest_version = env[:machine].provider.driver.read_guest_additions_version
          if !version
            env[:ui].warn I18n.t("vagrant.actions.vm.check_guest_additions.not_detected")
          else
            env[:machine].provider.driver.verify! =~ /\w+ (\d.+)/
            os_version = $1

            if guest_version != os_version
              env[:ui].warn(I18n.t("vagrant.actions.vm.check_guest_additions.version_mismatch",
                                   :guest_version => guest_version,
                                   :parallels_version => os_version))
            end
          end

          # Continue
          @app.call(env)
        end

      end
    end
  end
end
