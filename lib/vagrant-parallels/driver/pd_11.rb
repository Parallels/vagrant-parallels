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
      end
    end
  end
end
