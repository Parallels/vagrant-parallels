module VagrantPlugins
  module Parallels
    module Action
      class RegisterTemplate
        def initialize(app, env)
          @app = app
        end

        def call(env)
          pvm_glob = Pathname.glob(env[:machine].box.directory.join('*.pvm')).first
          # TODO: Handle error cases better, throw a Vagrant error and not a stack trace etc.
          pvm_file = File.realpath pvm_glob.to_s

          unless env[:machine].provider.driver.registered?(pvm_file)
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
