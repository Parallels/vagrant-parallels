module VagrantPlugins
  module Parallels
    module Action
      # Checks that Parallels is installed and ready to be used.
      class CheckParallels
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # This verifies that Parallels is installed and the driver is
          # ready to function. If not, then an exception will be raised
          # which will break us out of execution of the middleware sequence.
          env[:machine].provider.driver.verify!

          # Carry on.
          @app.call(env)
        end
      end
    end
  end
end