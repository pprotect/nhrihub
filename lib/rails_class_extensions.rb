module PermissionCheck
  def link_to(name, options = {}, html_options = {}, &block)
    url = url_from_options(options)
    # assume to be permitted
    return link_to_without_permission_check(name, options, html_options, &block) if javascript?(url)

    return link_to_without_permission_check(name, options, html_options, &block) if current_user_permitted?(rack_endpoint_for(url, html_options))
    ""
  end

private
  def url_from_options(options)
    case options
    when String
      options
    when :back
      request.env["HTTP_REFERER"] || 'javascript:history.back()'
    else
      self.url_for(options)
    end
  end

  def javascript?(url)
    url == '#' || url == 'javascript:void(0)' || url == 'javascript: void(0)'
  end

  def rack_endpoint_for(url, html_options)
    opt = url.split("?")
    opt = opt[0]
    opt = opt.gsub(/http\:\/\/(.*?)\//,"/")
    route = Rails.application.routes.recognize_path(opt, :method=>method(html_options).to_sym)
    controller = route[:controller]
    action = route[:action]

    {:controller => controller, :action => action}
  end

  def method(html_options)
    html_options.blank? || html_options[:method].nil? ? :get : html_options[:method]
  end

end

module ActionView::Helpers::UrlHelper
  # here we overwrite the link_to  and button_to methods,
  # to produce a zero length string if the current user is not permitted
  # for this action, otherwise a proper link is generated
  alias_method :link_to_without_permission_check, :link_to # link_to_without_permission_check points to ORIGINAL
  prepend PermissionCheck # link_to is intercepted by this prepended PermissionChecke module
  alias_method :link_to_with_permission_check, :link_to # link_to_with_permission_check intercepted by prepended PermissionCheck module
end

module ActionView
  module Helpers
    module Tags # :nodoc:
      class TextArea < Base # :nodoc:
        def render
          options = @options.stringify_keys
          add_default_name_and_id(options)

          if size = options.delete("size")
            options["cols"], options["rows"] = size.split("x") if size.respond_to?(:split)
          end

          # leave the value attribute in the tag instead of removing it
          content_tag("textarea", options.fetch("value") { value_before_type_cast(object) }, options)
        end
      end
    end
  end
end

class String
  def unspaced
    self.gsub(/\s*/,'')
  end
end

class TrueClass
  def y_n
    'yes'
  end
end

class FalseClass
  def y_n
    'no'
  end
end

class NilClass
  def y_n
    'no'
  end
end

class Time
  def distance_of_time_in_words(other_time)
    end_time = self
    change_date = other_time
    diff = (end_time - change_date).to_f/60/60/24
    days = diff.round
    days_in_year = 365
    days_in_month = days_in_year/12
    case days
    when 0...30
      "#{days} #{'day'.pluralize(days)}"
    when 30...365
      whole_months = (diff.to_f/days_in_month).to_i
      remaining_days = days%days_in_month
      string = "#{whole_months} #{'month'.pluralize(whole_months)}"
      string += ", #{remaining_days.to_i} #{'day'.pluralize(remaining_days.to_i)}" unless remaining_days.to_i.zero?
      string
    else
      whole_years = (days.to_f/days_in_year).to_i
      remaining_days = days%days_in_year
      months = (remaining_days.to_f/days_in_month).to_i
      remaining_days = remaining_days%days_in_month

      string = "#{whole_years} #{'year'.pluralize(whole_years)}"
      string += ", #{months} #{'month'.pluralize(months)}" unless months.zero?
      string += ", #{remaining_days.to_i} #{'day'.pluralize(remaining_days.to_i)}" unless remaining_days.to_i.zero?
      string
    end
  end
end
