module AccessLogger
  def with_logging(request, &block)
    begin
      request_params = {:ip => request.remote_ip, :ua => request.user_agent}
      access_event = AccessEvent.new
      xhr = !!(request.xhr?)
      block.call
    rescue User::AuthenticationError => exception
      attrs = exception.interpolation_params
      attrs.each{|(attr,val)| access_event.send(:"#{attr}=",val)}
      access_event.save
      failed_login exception.message
    end
  end
end
