class AccessLog
  LogFile = Rails.root.join('log', "#{Rails.env}_access.log")
  class << self
    cattr_accessor :logger
    delegate :debug, :info, :warn, :error, :fatal, :to => :logger
  end
end
