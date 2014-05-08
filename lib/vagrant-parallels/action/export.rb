module VagrantPlugins
  module Parallels
    module Action
      class Export
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::plugins::parallels::export")
        end

        def call(env)
          @env = env
          if env[:machine].state.id != :stopped
            raise Vagrant::Errors::VMPowerOffToPackage
          end

          name = "#{env[:root_path].basename.to_s}_#{env[:machine].name}"
          name.gsub!(/[^-a-z0-9_]/i, "")

          # Check the name is not in use
          if @env[:machine].provider.driver.read_vms.has_key?(@template_name)
            @template_name << rand(100000).to_s
          end


          @template_name = gen_template_name
          @template_uuid = export
          compact_template
          unregister_template

          @app.call(env)
        end

        def recover(env)
          @env = env
          unregister_template
        end

        private

        def gen_template_name
          # Use configured name if it is specified, or generate the new one
          name = @env[:machine].provider_config.name
          if !name
            name = "#{@env[:root_path].basename.to_s}_#{@env[:machine].name}"
            name.gsub!(/[^-a-z0-9_]/i, "")
          end
          tpl_name = "#{name}_box"

          # Ensure that the name is not in use
          if @env[:machine].provider.driver.read_vms.has_key?(tpl_name)
            tpl_name << "_#{rand(1000)}"
          end

          tpl_name
        end

        def export
          @env[:ui].info I18n.t("vagrant.actions.vm.export.exporting")
          tpl_uuid = @env[:machine].provider.driver.export(@env["export.temp_dir"], @template_name) do |progress|
            @env[:ui].clear_line
            @env[:ui].report_progress(progress, 100, false)

            # # If we got interrupted, then the import could have been interrupted.
            # Just rise an exception and then 'recover' will be called to cleanup.
            raise Vagrant::Errors::VagrantInterrupt if @env[:interrupted]
          end

          # Clear the line a final time so the next data can appear
          # alone on the line.
          @env[:ui].clear_line

          tpl_uuid
        end

        def compact_template
          @env[:ui].info I18n.t("vagrant_parallels.actions.vm.export.compacting")
          @env[:machine].provider.driver.compact(@template_uuid) do |progress|
            @env[:ui].clear_line
            @env[:ui].report_progress(progress, 100, false)
          end

          # Clear the line a final time so the next data can appear
          # alone on the line.
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
