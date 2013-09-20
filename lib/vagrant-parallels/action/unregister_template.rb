module VagrantPlugins
  module Parallels
    module Action
      class UnregisterTemplate
        def initialize(app, env)
          @app = app
        end

        def call(env)
          vm_name = Pathname.glob(
            env[:machine].box.directory.join('*.pvm')
            ).first.basename.to_s[0...-4]

          if env[:machine].provider.driver.registered?(vm_name)
            env[:machine].provider.driver.unregister(vm_name)
          end
          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end
    end
  end
end
