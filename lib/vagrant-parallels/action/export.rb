require 'nokogiri'

module VagrantPlugins
  module Parallels
    module Action
      class Export
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::export')
        end

        def call(env)
          if env[:machine].state.id != :stopped
            raise Vagrant::Errors::VMPowerOffToPackage
          end

          # Clone source VM to the temporary copy
          clone(env)
          @home_path = env[:machine].provider.driver.read_settings(env[:package_box_id]).fetch('Home')
          @hdd_list = Dir.glob(File.join(@home_path, '*.hdd'))

          # Convert to full-sized VM, copy all external and linked disks (if any)
          convert_to_full(env)

          # Compact all virtual disks 
          # Note: The macvm (macOS VM on Apple Silicon Macs) only supports PLAIN virtual disks. 
          # As a result, these disks cannot be compacted. Therefore, the compacting step 
          # should be skipped for macvms.

          if !Util::Common::is_macvm(env[:machine])
            compact(env)
          end

          # Preparations completed. Unregister before packaging
          unregister_vm(env)

          @app.call(env)
        end

        def recover(env)
          unregister_vm(env)
        end

        private

        def box_vm_name(env)
          # Use configured name if it is specified, or generate the new one
          name = env[:machine].provider_config.name
          if !name
            name = "#{env[:root_path].basename.to_s}_#{env[:machine].name}"
            name.gsub!(/[^-a-z0-9_]/i, '')
          end

          vm_name = "#{name}_box"

          # Ensure that the name is not in use
          ind = 0
          while env[:machine].provider.driver.read_vms.has_key?(vm_name)
            ind += 1
            vm_name = "#{name}_box_#{ind}"
          end

          vm_name
        end

        def clone(env)
          env[:ui].info I18n.t('vagrant.actions.vm.export.exporting')

          options = {
            dst: env['export.temp_dir'].to_s
          }

          env[:package_box_id] = env[:machine].provider.driver.clone_vm(
            env[:machine].id, options) do |progress|
            env[:ui].clear_line
            env[:ui].report_progress(progress, 100, false)

            # If we got interrupted, then rise an exception and 'recover'
            # will be called to cleanup.
            raise Vagrant::Errors::VagrantInterrupt if env[:interrupted]
          end

          # Set the box VM name
          name = box_vm_name(env)
          env[:machine].provider.driver.set_name(env[:package_box_id], name)

          # Clear the line a final time so the next data can appear
          # alone on the line.
          env[:ui].clear_line
        end

        def convert_to_full(env)
          is_linked = false

          @hdd_list.each do |hdd_dir|
            disk_desc = File.join(hdd_dir, 'DiskDescriptor.xml')
            xml = Nokogiri::XML(File.open disk_desc)

            linked_images = xml.xpath('//Parallels_disk_image/StorageData/Storage/Image/File').select do |hds|
              Pathname.new(hds).absolute?
            end

            # If this is a regular, not linked HDD, then skip it. Otherwise,
            # remember this VM as a linked clone.
            next if linked_images.empty?
            is_linked = true


            env[:ui].info I18n.t('vagrant_parallels.actions.vm.export.copying_linked_disks')
            linked_images.each do |hds|
              hds_path = hds.text

              if !File.exist?(hds_path)
                raise VagrantPlugins::Parallels::Errors::ExternalDiskNotFound,
                      path: hds_path
              end

              FileUtils.cp(hds_path, hdd_dir, preserve: true)

              # Save relative hds path to the XML file
              hds.content = File.basename(hds_path)
            end

            File.open(disk_desc, 'w') do |f|
              f.write xml.to_xml
            end
          end

          # Flush elements LinkedVmUuid, LinkedSnapshotUuid from "config.pvs"
          if is_linked
            @logger.debug 'Converting linked clone to the regular VM'
            config_pvs = File.join(@home_path, 'config.pvs')

            xml = Nokogiri::XML(File.open(config_pvs))
            xml.xpath('//ParallelsVirtualMachine/Identification/LinkedVmUuid').first.content = ''
            xml.xpath('//ParallelsVirtualMachine/Identification/LinkedSnapshotUuid').first.content = ''

            File.open(config_pvs, 'w') do |f|
              f.write xml.to_xml
            end
          end
        end

        def compact(env)
          env[:ui].info I18n.t('vagrant_parallels.actions.vm.export.compacting')
          @hdd_list.each do |hdd|
            env[:machine].provider.driver.compact_hdd(hdd) do |progress|
              env[:ui].clear_line
              env[:ui].report_progress(progress, 100, false)
            end
            # Clear the line a final time so the next data can appear
            # alone on the line.
            env[:ui].clear_line
          end
        end

        def unregister_vm(env)
          return if !env[:package_box_id]
          @logger.info("Unregister the box VM: '#{env[:package_box_id]}'")
          env[:machine].provider.driver.unregister(env[:package_box_id])
        end
      end
    end
  end
end
