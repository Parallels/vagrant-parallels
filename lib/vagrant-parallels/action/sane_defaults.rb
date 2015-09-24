require 'log4r'

module VagrantPlugins
  module Parallels
    module Action
      class SaneDefaults
        def initialize(app, env)
          @logger = Log4r::Logger.new('vagrant_parallels::action::sanedefaults')
          @app = app
        end

        def call(env)
          # Set the env on an instance variable so we can access it in
          # helpers.
          @env = env

          @app.call(env)
        end
      end
    end
  end
end
