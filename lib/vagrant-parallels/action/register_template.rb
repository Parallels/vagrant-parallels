module VagrantPlugins
  module Parallels
    module Action
      class RegisterTemplate
        def initialize(app, env)
          @app = app
        end

        def call(env)
          pvm_file = Pathname.glob(env[:machine].box.directory.join('*.pvm')).first

          unless env[:machine].provider.driver.registered?(pvm_file.basename.to_s[0...-4])
            env[:machine].provider.driver.register(pvm_file.to_s)
          end
          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end
    end
  end
end
