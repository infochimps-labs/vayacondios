class Vayacondios
  # Are we operating on JSON Hashes (Vayacondios) or on JSON arrays
  # (Vayacondios Legacy)? These classes determine which to use.

  class StandardContentsHandler
    def wrap_contents(contents) {contents: contents} end
    def extract_contents(document) document['contents'] end
    def proper_request(document)
      document.is_a? Hash and document.fetch('_json', {}).is_a? Hash
    end
  end

  class LegacyContentsHandler
    def wrap_contents(contents) contents end
    def extract_contents(document) document.fetch('_json', {}) end
    def proper_request(document)
      document.is_a? Array or document.fetch('_json', {}).is_a? Array
    end
  end

  def self.legacy_switch
    @@legacy_switch ||= get_legacy_switch(Settings[:vayacondios][:legacy])
  end

  def self.force_legacy_mode on
    @@legacy_switch = get_legacy_switch on
  end

  private

  def self.get_legacy_switch on
    (on ? LegacyContentsHandler : StandardContentsHandler).new
  end
end

