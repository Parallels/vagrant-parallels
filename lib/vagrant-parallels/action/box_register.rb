require 'log4r'

#require 'digest/md5'

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
          pvm = Dir.glob(env[:machine].box.directory.join('*.pvm')).first

          if !pvm
            raise Errors::BoxImageNotFound, name: env[:machine].box.name
          end

          pvm
        end

        def box_id(env, box_path)
          # Get the box image UUID from XML-based configuration file
          tpl_config = File.join(box_path, 'config.pvs')
          xml = Nokogiri::XML(File.open(tpl_config))
          id = xml.xpath('//ParallelsVirtualMachine/Identification/VmUuid').text

          if !id
            raise Errors::BoxIDNotFound,
              name: env[:machine].box.name,
              config: tpl_config
          end

          id
        end

        def register_box(env)
          box_id_file = env[:machine].box.directory.join('box_id')

          # Read the master ID if we have it in the file.
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

          if env[:machine].provider_config.regen_src_uuid \
            && env[:machine].provider.pd_version_satisfies?('>= 10.1.2')
            options << '--regenerate-src-uuid'
          end

          # Register the box VM image
          env[:machine].provider.driver.register(pvm, options)
          env[:clone_id] = box_id(env, pvm)

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
