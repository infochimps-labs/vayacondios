require 'logger'

module LogHelper

  def log
    @logdev = StringIO.new
    Logger.new @logdev
  end

  def log_device
    @logdev
  end

  def log_content
    log_device.rewind
    log_device.read
  end
  
end
