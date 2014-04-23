require "pathname"

require "vagrant-parallels/plugin"
require "vagrant-parallels/version"

module VagrantPlugins
  module Parallels
    lib_path = Pathname.new(File.expand_path("../vagrant-parallels", __FILE__))
    autoload :Action, lib_path.join("action")
    autoload :Errors, lib_path.join("errors")

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end

    # This initializes the internationalization strings.
    def self.setup_i18n
      I18n.load_path << File.expand_path("locales/en.yml", Parallels.source_root)
      I18n.reload!
    end

    # This sets up our log level to be whatever VAGRANT_LOG is.
    def self.setup_logging
      require "log4r"

      level = nil
      begin
        level = Log4r.const_get(ENV["VAGRANT_LOG"].upcase)
      rescue NameError
        # This means that the logging constant wasn't found,
        # which is fine. We just keep `level` as `nil`. But
        # we tell the user.
        level = nil
      end

      # Some constants, such as "true" resolve to booleans, so the
      # above error checking doesn't catch it. This will check to make
      # sure that the log level is an integer, as Log4r requires.
      level = nil if !level.is_a?(Integer)

      # Set the logging level on all "vagrant" namespaced
      # logs as long as we have a valid level.
      if level
        logger = Log4r::Logger.new("vagrant_parallels")
        logger.outputters = Log4r::Outputter.stderr
        logger.level = level
        logger = nil
      end
    end
    Parallels.setup_logging
    Parallels.setup_i18n
  end
end
