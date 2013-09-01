module VagrantPlugins
  module Parallels
    module Action
      class ParallelsHalt
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          current_state = env[:machine].state.id
          if current_state == :running
            env[:ui].info I18n.t("vagrant.actions.vm.halt.graceful")
            env[:machine].provider.driver.halt
            env[:machine].provider.driver.halt(:force) if !wait_for_shutdown
          end

          @app.call(env)
        end

        def wait_for_shutdown
          @env[:ui].info I18n.t("vagrant.actions.vm.halt.waiting")

          @env[:machine].config.ssh.max_tries.to_i.times do |i|
            if !@env[:machine].provider.driver.ready?
              @env[:ui].info I18n.t("vagrant.actions.vm.halt.done")
              return true
            end

            # Return true so that the vm_failed_to_shutdown error doesn't
            # get shown
            return true if @env[:interrupted]

            sleep 2 if !@env["vagrant.test"]
          end

          @env[:ui].error I18n.t("vagrant.actions.vm.halt.failed")
          false
        end

      end
    end
  end
end
