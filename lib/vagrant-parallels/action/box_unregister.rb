require 'log4r'

module VagrantPlugins
  module Parallels
    module Action
      class BoxUnregister
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::box_unregister')
        end

        def call(env)
          # If we don't have a box, nothing to do
          if !env[:machine].box
            return @app.call(env)
          end

          unregister_box(env)

          # If we got interrupted, then the import could have been
          # interrupted and its not a big deal. Just return out.
          return if env[:interrupted]

          # Register completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          unregister_box(env)
        end

        private

        def unregister_box(env)
          if env[:clone_id] && env[:machine].provider.driver.vm_exists?(env[:clone_id])
            env[:ui].info I18n.t('vagrant_parallels.actions.vm.box.unregister')
            env[:machine].provider.driver.unregister(env[:clone_id])
          end
        end
      end
    end
  end
end
