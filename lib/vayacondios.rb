module Vayacondios
  # Version of the api
  API_VERSION            = 'v3'

  # Gem version for both client and server
  GEM_VERSION            = '0.3.0'

  # Default port to find/connect to for the server
  DEFAULT_SERVER_PORT    = 9000

  # Default address to bind/connect to for the server
  DEFAULT_SERVER_ADDRESS = 'localhost'

  module_function

  def library_dir
    File.expand_path('../..', __FILE__)
  end
end

# Alias for Vayacondios
Vcd = Vayacondios
