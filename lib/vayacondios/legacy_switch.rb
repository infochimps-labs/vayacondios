require 'gorillib/logger/log'

class Vayacondios
  # Are we operating on JSON Hashes (Vayacondios) or on JSON arrays
  # (Vayacondios Legacy)? These classes determine which to use.

  class StandardContentsHandler
    def wrap_contents(contents) {contents: contents} end
    def extract_contents(document) document['contents'] end
    def extract_response(document) document['contents'] end
    def proper_request(document) true end
  end

  class LegacyContentsHandler
    def wrap_contents(contents) contents end
    def extract_contents(document) document end
    def extract_response(document) document end
    def proper_request(document) true end
  end

  @@legacy_switch = nil

  def self.legacy_switch
    if @@legacy_switch.nil?
      legacy_mode_on = Settings[:vayacondios][:legacy]
      @@legacy_switch = get_legacy_switch(legacy_mode_on)
      Log.info("using #{legacy_mode_on ? 'legacy' : 'standard'} mode")
    end
    @@legacy_switch
  end

  def self.force_legacy_mode on
    Log.info("forcing #{on ? 'legacy' : 'standard'} mode")
    @@legacy_switch = get_legacy_switch on
  end

  private

  def self.get_legacy_switch on
    (on ? LegacyContentsHandler : StandardContentsHandler).new
  end
end

