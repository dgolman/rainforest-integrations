module Integrations
  class Base
    attr_reader :event_type, :payload, :settings, :run

    def initialize(event_type, payload, settings)
      @event_type = event_type
      @payload = payload
      @run = payload[:run] || {}
      @settings = Integrations::Settings.new(settings)
      validate_settings
    end

    # this key should match the key used to identify the integration in integrations.yml
    def self.key
      raise 'key must be defined in the child class'
    end

    # send_event will be the public facing method for all integrations. Please
    # overwrite with your custom behavior
    def send_event
      raise 'send_event must be defined in the child class'
    end

    protected

    def self.required_settings
      @required_settings ||= Integration.find(key).fetch('settings').map do |setting|
        if setting['required']
          setting.fetch('key')
        end
      end.compact
    end

    def validate_settings
      supplied_settings = settings.keys
      required_settings = self.class.required_settings
      missing_settings = required_settings - supplied_settings

      unless missing_settings.empty?
        raise Integrations::Error.new('misconfigured_integration', "Required settings '#{missing_settings.join(", ")}' were not supplied to #{self.class.key}")
      end
    end
  end
end
