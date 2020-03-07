module UserExceptionsLogger
  def with_logging(request, &block)
    begin
      request_params = {:request_ip => request.remote_ip, :request_user_agent => request.user_agent}
      block.call
    rescue ActiveRecord::RecordNotFound => exception
      AccessEvent.create(request_params.merge!(exception_type: "user/invalid_password_expiry_token"))
      raise
    rescue User::BlankPasswordExpiryToken => exception
      AccessEvent.create(request_params.merge!(exception.interpolation_params))
      raise
    rescue User::AuthenticationError => exception
      AccessEvent.create(request_params.merge!(exception.interpolation_params))
      raise
    end
  end
end
