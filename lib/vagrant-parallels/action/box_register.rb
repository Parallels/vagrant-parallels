require 'fileutils'
require 'log4r'
require 'nokogiri'

module VagrantPlugins
  module Parallels
    module Action
      class BoxRegister
        @@lock = Mutex.new

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::box_register')
        end

        def call(env)
          # If we don't have a box, nothing to do
          if !env[:machine].box
            return @app.call(env)
          end

          # Do the register while locked so that nobody else register
          # a box at the same time.
          @@lock.synchronize do
            lock_key = Digest::MD5.hexdigest(env[:machine].box.name)
            env[:machine].env.lock(lock_key, retry: true) do
              register_box(env)
            end
          end

          # If we got interrupted, then the import could have been
          # interrupted and its not a big deal. Just return out.
          return if env[:interrupted]

          # Register completed successfully. Continue the chain
          @app.call(env)
        end

        protected

        def box_path(env)
          res = Dir.glob(env[:machine].box.directory.join('*.{pvm,macvm}')).first

          if !res
            raise Errors::BoxImageNotFound, name: env[:machine].box.name
          end

          res
        end

        def box_id(env)
          # Get the box image UUID from XML-based configuration file
          tpl_config = File.join(box_path(env), 'config.pvs')
          xml = Nokogiri::XML(File.open(tpl_config))
          id = xml.xpath('//ParallelsVirtualMachine/Identification/VmUuid').text

          if !id
            raise Errors::BoxIDNotFound,
              name: env[:machine].box.name,
              config: tpl_config
          end

          id.delete('{}')
        end

        def lease_box_lock(env)
          lease_file = env[:machine].box.directory.join('box_lease_count')

          # If the temporary file, verify it is not too old. If its older than
          # 1 hour, delete it first because previous run may be failed.
          if lease_file.file? && lease_file.mtime.to_i < Time.now.to_i - 60 * 60
            lease_file.delete
          end

          # Increment a counter in the file. Create the file if it doesn't exist
          FileUtils.touch(lease_file)
          File.open(lease_file ,'r+') do |file|
            num = file.gets.to_i
            file.rewind
            file.puts num.next
            file.fsync
            file.flush
          end
        end

        def register_box(env)
          # Increment the lock counter in the temporary lease file
          lease_box_lock(env)

          # Read the box ID if we have it in the file.
          box_id_file = env[:machine].box.directory.join('box_id')
          env[:clone_id] = box_id_file.read.chomp if box_id_file.file?

          # If we have the ID and the VM exists already, then we
          # have nothing to do. Success!
          if env[:clone_id] && env[:machine].provider.driver.vm_exists?(env[:clone_id])
            @logger.info(
              "Box image '#{env[:machine].box.name}' is already registered " +
                "(id=#{env[:clone_id]}) - skipping register step.")
            return
          end

          env[:ui].info I18n.t('vagrant_parallels.actions.vm.box.register',
                        name: env[:machine].box.name)

          pvm = box_path(env)

          # We need the box ID to be the same for all parallel runs
          options = ['--preserve-uuid']

          # Register the box VM image
          env[:machine].provider.driver.register(pvm, options)
          env[:clone_id] = box_id(env)

          @logger.info(
            "Registered box #{env[:machine].box.name} with id #{env[:clone_id]}")

          @logger.debug("Writing box id '#{env[:clone_id]}' to #{box_id_file}")
          box_id_file.open('w+') do |f|
            f.write(env[:clone_id])
          end

        end
      end
    end
  end
end
