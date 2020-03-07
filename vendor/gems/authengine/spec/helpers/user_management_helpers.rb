require 'rspec/core/shared_context'

module UserManagementHelpers
  extend RSpec::Core::SharedContext

  def remove_user_two_factor_authentication_credentials(user)
    user = User.where(:login => user).first
    user.update(:public_key => nil, :public_key_handle => nil)
  end

  def disable_two_factor_authentication
    allow(ENV).to receive(:fetch)
    allow(ENV).to receive(:fetch).with("two_factor_authentication").and_return("disabled")
    remove_user_two_factor_authentication_credentials('admin')
    remove_user_two_factor_authentication_credentials('staff')
    visit "/en"
  end

  def enable_two_factor_authentication
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("two_factor_authentication").and_return("enabled")
    #raise "two-factor authentication must be enabled in config/env.yml for integration tests" unless TwoFactorAuthentication.enabled?
    visit "/en"
    configure_keystore
  end

  def user_record_for(user)
    page.find(:xpath, "//tr[contains(td/text(),\"#{user.last_first_name}\")]")
  end

  def norman_normal_to_be_in_the_database
    User.where(:firstName => "Norman", :lastName => "Normal").exists?
  end

  def norman_normal_account_is_activated 
    User.where(:firstName => "Norman", :lastName => "Normal").first.active?
  end

  def email_activation_link
    link_from_last_email
  end

  def new_password_activation_link
    link_from_last_email
  end

  def replacement_token_registration_link
    link_from_last_email
  end

  def signup
    page.find('.btn#sign_up').click
    wait_for_ajax
  end

  def submit_button
    page.find('.btn#submit')
  end

  def register_button
    page.find('.btn#register')
  end

private
  def link_from_last_email
    visit("/") # else there's no current_session yet from which to derive the url
    url = find_url_in_email
    host, port = get_url_params
    local_url = url.gsub(/^https:\/\/[^\/]*/,"#{host}:#{port}")
    "http://"+local_url # can't support https on localhost
  end

  def find_url_in_email
    email = ActionMailer::Base.deliveries.last
    Nokogiri::HTML(email.body.to_s).xpath(".//p/a").attr('href').value
  end

  def get_url_params
    if Capybara.current_session.server # real browser
      host = Capybara.current_session.server.host
      port = Capybara.current_session.server.port
    else # capybara-webkit
      host = Capybara.current_session.driver.request.host
      port = Capybara.current_session.driver.request.port
    end
    [host, port]
  end
end
