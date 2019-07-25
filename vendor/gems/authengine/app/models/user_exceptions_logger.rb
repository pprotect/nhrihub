module UserExceptionsLogger
  def with_logging(request, &block)
    begin
      request_params = {:request_ip => request.remote_ip, :request_user_agent => request.user_agent}
      block.call
    rescue User::AuthenticationError => exception
      AccessEvent.create(request_params.merge!(exception.interpolation_params))
      failed_login exception.message
    end
  end
end
