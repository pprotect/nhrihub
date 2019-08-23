class ApplicationMailer < ActionMailer::Base
  default from: "#{APPLICATION_NAME || "database"} Administrator<#{NO_REPLY_EMAIL}>"
  layout 'mailer'

  def mail
    super(options)
  end

  private
  def options
    {:'List-Unsubscribe-Post' => :'List-Unsubscribe=One-Click',
     :'List-Unsubscribe' => unsubscribe_url,
     :subject => t('.subject', org_name: ORGANIZATION_NAME, app_name: APPLICATION_NAME),
     :to => "#{@recipient.email}",
     :date => Time.now }
  end

  def unsubscribe_url
    params = { :locale => I18n.locale,
               :user_id => @recipient.id,
               :unsubscribe_code => @recipient.refresh_unsubscribe_code,
               :protocol => :https }
    admin_unsubscribe_url( params )
  end
end

