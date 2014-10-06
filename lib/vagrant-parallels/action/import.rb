module VagrantPlugins
  module Parallels
    module Action
      class Import
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::import')
        end

        def call(env)
          @machine = env[:machine]
          @template_path = Pathname.glob(@machine.box.directory.join('*.pvm')).first.to_s

          register_template
          import(env)
          unregister_template

          # Flag as erroneous and return if import failed
          raise VagrantPlugins::Parallels::Errors::VMImportFailure if !@machine.id

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          # We should to unregister template
          unregister_template

          if @machine.state.id != :not_created
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
          @logger.info("Register the box template: '#{@template_path}'")
          regen_uuid = @machine.provider_config.regen_box_uuid

          @machine.provider.driver.register(@template_path, regen_uuid)

          # Return the uuid of registered template
          @template_uuid = @machine.provider.driver.read_vms_paths[@template_path]
        end

        def import(env)
          env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                               :name => @machine.box.name)

          # Import the virtual machine
          @machine.id = @machine.provider.driver.import(@template_uuid) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)

            # # If we got interrupted, then the import could have been interrupted.
            # Just rise an exception and then 'recover' will be called to cleanup.
            raise Vagrant::Errors::VagrantInterrupt if env[:interrupted]
          end

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          env[:ui].clear_line
        end

        def unregister_template
          @logger.info("Unregister the box template: '#{@template_uuid}'")
          @machine.provider.driver.unregister(@template_uuid)
        end
      end
    end
  end
end
