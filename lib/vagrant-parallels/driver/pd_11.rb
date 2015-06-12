require 'log4r'

require 'vagrant/util/platform'

require File.expand_path('../pd_10', __FILE__)

module VagrantPlugins
  module Parallels
    module Driver
      # Driver for Parallels Desktop 11.
      class PD_11 < PD_10
        def initialize(uuid)
          super(uuid)

          @logger = Log4r::Logger.new('vagrant_parallels::driver::pd_11')
        end

        def clone_vm(src_name, dst_name, options={})
          args = ['clone', src_name, '--name', dst_name]
          args << '--template' if options[:template]
          args.concat(['--dst', options[:dst]]) if options[:dst]

          # Linked clone options
          args << '--linked' if options[:linked]
          args.concat(['--id', options[:snapshot_id]]) if options[:snapshot_id]

          execute_prlctl(*args) do |type, data|
            lines = data.split("\r")
            # The progress of the import will be in the last line. Do a greedy
            # regular expression to find what we're looking for.
            if lines.last =~ /.+?(\d{,3}) ?%/
              yield $1.to_i if block_given?
            end
          end
          read_vms[dst_name]
        end

        def create_snapshot(uuid, options)
          args = ['snapshot', uuid]
          args.concat(['--name', options[:name]]) if options[:name]
          args.concat(['--description', options[:desc]]) if options[:desc]

          stdout = execute_prlctl(*args)
          if stdout =~ /\{([\w-]+)\}/
            return $1
          end

          raise Errors::SnapshotIdNotDetected, stdout: stdout
        end

        def read_current_snapshot(uuid)
          if execute_prlctl('snapshot-list', uuid) =~ /\*\{([\w-]+)\}/
            return $1
          end

          nil
        end
      end
    end
  end
end
