class AccessLogger
  def self.before_save(session)
    exception_type = session.persisted? ? 'logout' : 'login'
    AccessEvent.create(exception_type: exception_type,
                       user: session.user,
                       request_user_agent: session.request.user_agent,
                       request_ip: session.request.ip)
  end
end
