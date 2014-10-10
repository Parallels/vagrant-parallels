require 'nokogiri'

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

          # Register template to be able to clone it further
          register_template(template_path.to_s)

          # Get template name. It might be changed during registration if name
          # collision has been occurred
          tpl_name = template_name(template_path)

          # Import VM, e.q. clone it from registered template
          import(env, tpl_name)

          # Hide template since we dont need it anymore
          unregister_template(tpl_name)

          # Flag as erroneous and return if import failed
          raise Errors::VMImportFailure if !@machine.id

          # Import completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          # We should to unregister template
          tpl_name = template_name(template_path)
          unregister_template(tpl_name)

          if @machine.state.id != :not_created
            return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)
            return if env["vagrant_parallels.error"].is_a?(Errors::VagrantParallelsError)

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

        def register_template(tpl_path_s)
          @logger.info("Register the box template: '#{tpl_path_s}'")
          regen_uuid = @machine.provider_config.regen_box_uuid

          @machine.provider.driver.register(tpl_path_s, regen_uuid)
        end

        def template_path
          Pathname.glob(@machine.box.directory.join('*.pvm')).first
        end

        def template_name(tpl_path)
          # Get template name from XML-based configuration file
          tpl_config = tpl_path.join('config.pvs')
          xml = Nokogiri::XML(File.open(tpl_config))
          name = xml.xpath('//ParallelsVirtualMachine/Identification/VmName').text

          if !name
            raise Errors::ParallelsTplNameNotFound, config_path: tpl_config
          end

          name
        end

        def import(env, tpl_name)
          env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                               :name => @machine.box.name)
          # Import the virtual machine
          @machine.id = @machine.provider.driver.import(tpl_name) do |progress|
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

        def unregister_template(tpl_name)
          @logger.info("Unregister the box template: '#{tpl_name}'")
          @machine.provider.driver.unregister(tpl_name)
        end
      end
    end
  end
end
