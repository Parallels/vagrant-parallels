module VagrantPlugins
  module Parallels
    module Action
      class Import
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                               :name => env[:machine].box.name)

          prefix = env[:root_path].basename.to_s
          prefix.gsub!(/[^-a-z0-9_]/i, "")
          vm_name = prefix + "_#{Time.now.to_i}"

          # Verify the name is not taken
          vms = env[:machine].provider.driver.list_vms
          raise Vagrant::Errors::VMNameExists, :name => vm_name if vms.include?(vm_name)

          # Import the virtual machine
          template_name = Pathname.glob(
              env[:machine].box.directory.join('*.pvm')
            ).first.basename.to_s[0...-4]

          env[:machine].id = env[:machine].provider.driver.import(template_name, vm_name) do |progress|
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
