module VagrantPlugins
  module Parallels
    module Action
      class Import
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::plugins::parallels::import")
        end

        def call(env)
          @env = env
          @template_path = File.realpath(Pathname.glob(env[:machine].box.directory.join('*.pvm')).first)
          @template_uuid = register_template
          import
          unregister_template

          # Flag as erroneous and return if import failed
          raise Vagrant::Errors::VMImportFailure if !env[:machine].id

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          @env = env
          # We should to unregister template
          unregister_template

          if env[:machine].provider.state.id != :not_created
            return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)
            return if env["vagrant_parallels.error"].is_a?(VagrantPlugins::Parallels::Errors::VagrantParallelsError)

            # If we're not supposed to destroy on error then just return
            return if !env[:destroy_on_error]

            # Interrupted, destroy the VM. We note that we don't want to
            # validate the configuration here, and we don't want to confirm
            # we want to destroy.
            destroy_env = env.clone
            destroy_env[:config_validate] = false
            destroy_env[:force_confirm_destroy] = true
            env[:action_runner].run(Action.action_destroy, destroy_env)
          end
        end

        protected

        def register_template
          if !@env[:machine].provider.driver.read_vms_paths.has_key?(@template_path)
            @logger.info("Register the box template: '#{@template_path}'")
            # We should also regenerate 'SourceVmUuid' to make sure that
            # SMBIOS UUID is unique [GH-113]
            @env[:machine].provider.driver.register(@template_path, regen_src_uuid=true)
          end

          # Return the uuid of registered template
          @env[:machine].provider.driver.read_vms_paths[@template_path]
        end

        def import
          @env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                               :name => @env[:machine].box.name)

          # Import the virtual machine
          @env[:machine].id = @env[:machine].provider.driver.import(@template_uuid) do |progress|
            @env[:ui].clear_line
            @env[:ui].report_progress(progress, 100, false)

            # # If we got interrupted, then the import could have been interrupted.
            # Just rise an exception and then 'recover' will be called to cleanup.
            raise Vagrant::Errors::VagrantInterrupt if @env[:interrupted]
          end

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          @env[:ui].clear_line
        end

        def unregister_template
          if @env[:machine].provider.driver.registered?(@template_uuid)
            @logger.info("Unregister the box template: '#{@template_uuid}'")
            @env[:machine].provider.driver.unregister(@template_uuid)
          end
        end
      end
    end
  end
end
