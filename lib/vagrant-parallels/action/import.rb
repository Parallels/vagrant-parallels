module VagrantPlugins
  module Parallels
    module Action
      class Import

        include Util

        def initialize(app, env)
          @app = app
        end

        #TODO: Clean up registered VM on interupt
        def call(env)
          env[:ui].info I18n.t("vagrant_parallels.actions.vm.import.importing",
                               :name => env[:machine].box.name)

          vm_name = generate_name(env[:root_path])

          # Verify the name is not taken
          if env[:machine].provider.driver.read_all_names.has_key?(vm_name)
            raise Vagrant::Errors::VMNameExists, :name => vm_name
          end

          # Import the virtual machine
          template_path = File.realpath(Pathname.glob(env[:machine].box.directory.join('*.pvm')).first)
          template_uuid = env[:machine].provider.driver.read_all_paths[template_path]

          env[:machine].id = env[:machine].provider.driver.import(template_uuid, vm_name) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)
          end

          # Clear the line one last time since the progress meter doesn't disappear
          # immediately.
          env[:ui].clear_line

          # If we got interrupted, then the import could have been
          # interrupted and its not a big deal. Just return out.
          return if env[:interrupted]

          # Flag as erroneous and return if import failed
          raise Vagrant::Errors::VMImportFailure if !env[:machine].id

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          if env[:machine].provider.state.id != :not_created
            return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

            # Interrupted, destroy the VM. We note that we don't want to
            # validate the configuration here, and we don't want to confirm
            # we want to destroy.
            destroy_env = env.clone
            destroy_env[:config_validate] = false
            destroy_env[:force_confirm_destroy] = true
            env[:action_runner].run(Action.action_destroy, destroy_env)
          end
        end
      end
    end
  end
end
