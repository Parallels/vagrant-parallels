module VagrantPlugins
  module Parallels
    class Config < Vagrant.plugin("2", :config)
      attr_reader :customizations
      attr_accessor :name

      def initialize
        @customizations   = []
        @name             = UNSET_VALUE
      end

      def customize(*command)
        event   = command.first.is_a?(String) ? command.shift : "pre-boot"
        command = command[0]
        @customizations << [event, command]
      end

      def validate(machine)
        errors = []
        valid_events = ["pre-import", "pre-boot", "post-boot"]
        @customizations.each do |event, _|
          if !valid_events.include?(event)
            errors << I18n.t(
              "vagrant.virtualbox.config.invalid_event",
              event: event.to_s,
              valid_events: valid_events.join(", "))
          end
        end
        @customizations.each do |event, command|
          if event == "pre-import" && command.index(:id)
            errors << I18n.t("vagrant.virtualbox.config.id_in_pre_import")
          end
        end

        { "Parallels Provider" => errors }

      end

    end
  end
end
