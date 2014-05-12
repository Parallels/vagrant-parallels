module VagrantPlugins
  module Parallels
    module Action
      # This middleware is meant to be used with Call and can check if
      # a version of Parallels Desktop satisfies the given constraint.
      class IsDriverVersion
        # @param [String] requirement Can be a full requirement specification,
        # like ">= 9.0.24229", or a list of them, like [">= 9","< 10.0.2"].
        def initialize(app, env, requirement, **opts)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::plugins::parallels::is_driver_version")
          @requirement = Gem::Requirement.new(requirement)
          @invert = !!opts[:invert]
        end

        def call(env)
          @logger.debug("Checking if 'prlctl' driver version satisfies '#{@requirement}'")
          driver_version = Gem::Version.new(env[:machine].provider.driver.version)
          @logger.debug("-- 'prlctl' driver version: #{driver_version}")

          env[:result] = @requirement.satisfied_by?(driver_version)
          env[:result] = !env[:result] if @invert
          @app.call(env)
        end
      end
    end
  end
end
