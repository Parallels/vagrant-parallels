module VagrantPlugins
  module Parallels
    module Action
      class UnregisterTemplate
        def initialize(app, env)
          @app = app
        end

        def call(env)
          template_path = File.realpath(Pathname.glob(
            env[:machine].box.directory.join('*.pvm')
            ).first)

          template_uuid = env[:machine].provider.driver.read_vms_paths[template_path]

          if env[:machine].provider.driver.registered?(template_path)
            env[:machine].provider.driver.unregister(template_uuid)
          end
          # Call the next if we have one (but we shouldn't, since this
          # middleware is built to run with the Call-type middlewares)
          @app.call(env)
        end
      end
    end
  end
end
