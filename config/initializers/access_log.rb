AccessLog.logger = Logger.new(AccessLog::LogFile)
AccessLog.logger.level = 'info' # could be debug, info, warn, error or fatal
