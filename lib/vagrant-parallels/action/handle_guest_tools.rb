module VagrantPlugins
  module Parallels
    module Action
      class HandleGuestTools
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::handle_guest_tools')
        end

        def call(env)
          @machine = env[:machine]

          if !@machine.provider_config.check_guest_tools
            @logger.info("Not checking Parallels Tools because of configuration")
            return @app.call(env)
          end

          env[:ui].output(I18n.t("vagrant_parallels.actions.vm.handle_guest_tools.checking"))

          tools_state = @machine.provider.driver.read_guest_tools_state

          if tools_state == :installed
            @logger.info("The proper version of Parallels Tools is already installed")
            return @app.call(env)
          elsif tools_state == :outdated
            env[:ui].warn(I18n.t("vagrant_parallels.actions.vm.handle_guest_tools.outdated"))
          else
            env[:ui].warn(I18n.t("vagrant_parallels.actions.vm.handle_guest_tools.not_detected"))
          end

          if !@machine.provider_config.update_guest_tools
            @logger.info("Not updating Parallels Tools because of configuration")
            return @app.call(env)
          end

          # Update/Install Parallels Tools
          if @machine.guest.capability?(:install_parallels_tools)
            env[:ui].output(I18n.t("vagrant_parallels.actions.vm.handle_guest_tools.installing"))
            @machine.guest.capability(:install_parallels_tools)
          else
            env[:ui].warn(I18n.t("vagrant_parallels.actions.vm.handle_guest_tools.cant_install"))
          end

          # Continue
          @app.call(env)
        end

      end
    end
  end
end
