module VagrantPlugins
  module Parallels
    module Action
      class Resume
        def initialize(app, env)
          @app = app
        end

        def call(env)
          current_state = env[:machine].state.id

          # Driver method "resume" works for suspended and paused state as well
          if current_state == :suspended
            env[:ui].info I18n.t('vagrant.actions.vm.resume.resuming')
            env[:machine].provider.driver.resume
          elsif current_state == :paused
            env[:ui].info I18n.t('vagrant.actions.vm.resume.unpausing')
            env[:machine].provider.driver.resume
          end

          @app.call(env)
        end
      end
    end
  end
end
