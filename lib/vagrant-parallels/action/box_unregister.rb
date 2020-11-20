require 'log4r'

module VagrantPlugins
  module Parallels
    module Action
      class BoxUnregister
        @@lock = Mutex.new

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new('vagrant_parallels::action::box_unregister')
        end

        def call(env)
          # If we don't have a box, nothing to do
          if !env[:machine].box
            return @app.call(env)
          end

          @@lock.synchronize do
            lock_key = Digest::MD5.hexdigest(env[:machine].box.name)
            env[:machine].env.lock(lock_key, retry: true) do
              unregister_box(env)
            end
          end

          # If we got interrupted, then the import could have been
          # interrupted and its not a big deal. Just return out.
          return if env[:interrupted]

          # Register completed successfully. Continue the chain
          @app.call(env)
        end

        def recover(env)
          # If we don't have a box, nothing to do
          return if !env[:machine].box

          unregister_box(env)
        end

        private

        def release_box_lock(lease_file)
          return if !lease_file.file?

          # Decrement the counter in the lease file
          File.open(lease_file,'r+') do |file|
            num = file.gets.to_i
            file.rewind
            file.puts(num - 1)
            file.fsync
            file.flush
          end

          # Delete the lease file if we were the last who needed this box.
          # Then the box image will be unregistered.
          lease_file.delete if lease_file.read.chomp.to_i <= 0
        end

        def unregister_box(env)
          # Release the box lock
          lease_file = env[:machine].box.directory.join('box_lease_count')
          release_box_lock(lease_file)

          # Do not unregister the box image if the temporary lease file exists
          # Most likely it is cloning to another Vagrant env (in parallel run)
          return if lease_file.file?

          if env[:clone_id] && env[:machine].provider.driver.vm_exists?(env[:clone_id])
            env[:ui].info I18n.t('vagrant_parallels.actions.vm.box.unregister')
            env[:machine].provider.driver.unregister(env[:clone_id])
          end
        end
      end
    end
  end
end
