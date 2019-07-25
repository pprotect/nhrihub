module AccessEventsHelper
  def timestamp
    @access_event.created_at.localtime.to_formatted_s(:long)
  end

  def log_entry
    I18n.t("#{@access_event.exception_type}.access_log_message", @access_event.interpolation_attributes)
  end

  def event_outcome
    ["login", "logout"].include?(@access_event.exception_type) ?  "success" : "fail"
  end
end
