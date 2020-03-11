require "rails_helper"
require 'login_helpers'
require 'navigation_helpers'
require_relative '../helpers/user_management_helpers'
require 'access_log_helpers'

feature "Password management, admin resets user password", :js => true do
  include RealLoggedInEnAdminUserHelper # logs in as admin
  include NavigationHelpers
  include UserManagementHelpers
  include AccessLogHelpers

  before do
    visit '/en'
    toggle_navigation_dropdown("Admin")
    select_dropdown_menu_item("Manage users")
  end

  scenario "normal operation" do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      expect{ click_link('reset password') }.to change { ActionMailer::Base.deliveries.length }.by 1
    end
    expect(page_heading).to eq "Manage users"
    expect(flash_message).to match /A password reset email has been sent to/

    click_link('Logout')
    # user whose password was reset responds to the link in the email
    visit(new_password_activation_link)
    configure_keystore
    expect(page_heading).to match /Select new password for/
    fill_in(:user_password, :with => "shinynewsecret&")
    fill_in(:user_password_confirmation, :with => "shinynewsecret&")
    original_public_key = User.last.public_key
    submit_button.click
    wait_for_authentication
    expect(flash_message).to eq "Your new password has been saved, you may login below."
    expect(User.last.public_key).to eq original_public_key
    expect(access_event.exception_type).to eq "user/admin_reset_password_replacement"
    fill_in "User name", :with => "staff"
    fill_in "Password", :with => "shinynewsecret&"
    login_button.click
    sleep(0.2)
    expect(flash_message).to eq "Logged in successfully"
    click_link('Logout')
  end

  scenario "user enters different passwords" do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      click_link('reset password')
    end
    expect(page_heading).to eq "Manage users"
    expect(flash_message).to match /A password reset email has been sent to/
    click_link('Logout')
    # user whose password was reset responds to the link in the email
    visit(new_password_activation_link)
    configure_keystore
    expect(page_heading).to match /Select new password for/
    fill_in(:user_password, :with => "shinynewsecret")
    fill_in(:user_password_confirmation, :with => "differentsecret")
    submit_button.click
    wait_for_authentication
    expect(page_heading).to match /Select new password for/
    expect(page).to have_selector("#message_block .error li", text: "Password Password must contain !@#%$^&*()-+<>")
    expect(page).to have_selector("#message_block .error li", text: "Password confirmation doesn't match password, please try again.")
  end

  scenario "user uses incorrect password reset_token" do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      click_link('reset password')
    end
    click_link('Logout')

    # user whose password was reset responds to the link in the email
    url_with_bogus_password_reset_token = new_password_activation_link.gsub(/[^\/]*$/,'bogus_password_reset_code')
    visit(url_with_bogus_password_reset_token  )
    expect(flash_message).to eq "User not found"
  end

  scenario "user uses blank password reset token" do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      click_link('reset password')
    end
    click_link('Logout')

    # user whose password was reset responds to the link in the email
    # but the reset token is blank
    url_with_blank_password_reset_token = new_password_activation_link.gsub(/[^\/]*$/,'')
    visit(url_with_blank_password_reset_token  )
    expect(flash_message).to eq "Invalid password reset."
  end
end

feature "Password management, user forgets password", :js => true do
  include NavigationHelpers
  include UserManagementHelpers
  include RegisteredUserHelper
  include UserManagementHelpers

  before do
    enable_two_factor_authentication
  end

  it "user does not enter a username" do
    page.find("#forgot_password").click
    expect(flash_message).to match /You must enter your username/
    fill_in "User name", :with => "admin"
    expect(flash_message).to be_blank
  end

  it "user tries to reset password but login not found" do
    expect(page).to have_selector("h1", :text => "Please log in")
    fill_in "User name", :with => "bozo"
    expect{ page.find("#forgot_password").click; wait_for_ajax}.not_to change { ActionMailer::Base.deliveries.count }
    expect(flash_message).to match /A password reset email has been sent to the email address for your account/
  end

  it "user tries to reset but account was not activated" do
    user = User.where(:login => 'staff').first
    user.send(:update_attribute, :activated_at, nil)
    expect(page).to have_selector("h1", :text => "Please log in")
    fill_in "User name", :with => "staff"
    expect{ page.find("#forgot_password").click; wait_for_ajax}.not_to change { ActionMailer::Base.deliveries.count }
    expect(flash_message).to match /The account is not activated, please see the administrator/
  end

  it "user tries to reset but account was disabled" do
    user = User.where(:login => 'staff').first
    user.update_column(:enabled , false)
    expect(page).to have_selector("h1", :text => "Please log in")
    fill_in "User name", :with => "staff"
    expect{ page.find("#forgot_password").click; wait_for_ajax}.not_to change { ActionMailer::Base.deliveries.count }
    expect(flash_message).to match /The account is disabled, please see the administrator/
  end

  it "should send an email to the user, from which the user may set new password" do
    expect(page).to have_selector("h1", :text => "Please log in")
    fill_in "User name", :with => "staff"
    expect{ page.find("#forgot_password").click; wait_for_ajax}.to change { ActionMailer::Base.deliveries.count }.by(1)
    expect(flash_message).to match /A password reset email has been sent to the email address for your account/
    expect(page.find('#login').value).to be_blank

    visit email_activation_link
    expect(page_heading).to match /Select new password for #{User.last.first_last_name}/
    fill_in(:user_password, :with => "shinynewsecret#")
    fill_in(:user_password_confirmation, :with => "shinynewsecret#")
    original_public_key = User.last.public_key
    submit_button.click
    wait_for_authentication
    expect(flash_message).to eq "Your new password has been saved, you may login below."
    expect(User.last.public_key).to eq original_public_key
    fill_in "User name", :with => "staff"
    fill_in "Password", :with => "shinynewsecret#"
    login_button.click
    sleep(0.5)
    expect(flash_message).to eq "Logged in successfully"
  end
end

feature "Password management, user's password has expired", js: true do
  include NavigationHelpers
  include RegisteredUserHelper
  include UserManagementHelpers
  include AccessLogHelpers
  let(:user){ @staff_user }

  before do
    disable_two_factor_authentication
    force_expiration_of_password
  end

  it "should not trigger password expiry change if user fails to authenticate password" do
    fill_in "User name", :with => "staff"
    fill_in "Password", :with => "wrongpassword"
    login_button.click
    expect(flash_message).to have_text("Your username or password is incorrect.")
    expect(page_heading).to eq "Please log in"
    expect(access_event.exception_type).to eq "user/invalid_password"
    expect(access_event.request_ip).not_to be_nil
    expect(access_event.request_user_agent).not_to be_nil
  end

  it "should disallow access to password change page for blank password_expiry_code" do
    visit admin_expired_password_path(:en)
    expect(page_heading).to eq "Please log in"
    expect(flash_message).to eq "Invalid password expiry code"
    expect(access_event.exception_type).to eq "user/blank_password_expiry_token"
    expect(access_event.login).to be_nil
    expect(access_event.request_ip).not_to be_nil
    expect(access_event.request_user_agent).not_to be_nil
  end

  it "should disallow access to password change page for invalid password expiry_code" do
    visit admin_expired_password_path(:en, "1234abcd")
    expect(page_heading).to eq "Please log in"
    expect(flash_message).to eq "Couldn't find User"
    expect(access_event.exception_type).to eq "user/invalid_password_expiry_token"
    expect(access_event.login).to be_nil
    expect(access_event.request_ip).not_to be_nil
    expect(access_event.request_user_agent).not_to be_nil
  end

  it "should guide the user to enter new password" do
    fill_in "User name", :with => "staff"
    fill_in "Password", :with => "password#"
    login_button.click
    expect(flash_message).to eq "Your password has expired, please select a new password."
    fill_in(:user_password, :with => "shinynewsecret#")
    fill_in(:user_password_confirmation, :with => "shinynewsecret#")
    submit_button.click
    expect(flash_message).to eq "Your new password has been saved, you may login below."
    expect(access_event.exception_type).to eq "user/expired_password_replacement"
    expect(access_event.login).to be_nil
    fill_in "User name", :with => "staff"
    fill_in "Password", :with => "shinynewsecret#"
    login_button.click
    sleep(0.2)
    expect(flash_message).to eq "Logged in successfully"
    click_link('Logout')
  end

  it "should warn user for invalid password" do
    fill_in "User name", :with => "staff"
    fill_in "Password", :with => "password#"
    login_button.click
    expect(flash_message).to eq "Your password has expired, please select a new password."
    fill_in(:user_password, :with => "shinynewsecret")
    fill_in(:user_password_confirmation, :with => "shinynewsecret")
    submit_button.click
    expect(page).to have_selector("#message_block .error li", text: "Password must contain !@#%$^&*()-+<>")
    fill_in(:user_password, :with => "shinynewsecret#")
    fill_in(:user_password_confirmation, :with => "shinynewsecret#")
    submit_button.click
    expect(flash_message).to eq "Your new password has been saved, you may login below."
    expect(access_event.exception_type).to eq "user/expired_password_replacement"
    expect(access_event.login).to be_nil
    fill_in "User name", :with => "staff"
    fill_in "Password", :with => "shinynewsecret#"
    login_button.click
    sleep(0.2)
    expect(flash_message).to eq "Logged in successfully"
    click_link('Logout')
  end

  it "should warn user for failed password confirmation" do
    fill_in "User name", :with => "staff"
    fill_in "Password", :with => "password#"
    login_button.click
    expect(flash_message).to eq "Your password has expired, please select a new password."
    fill_in(:user_password, :with => "shinynewsecret#")
    fill_in(:user_password_confirmation, :with => "anotherword")
    submit_button.click
    expect(page).to have_selector("#message_block .error li", text: "Password confirmation doesn't match password, please try again.")
    fill_in(:user_password, :with => "shinynewsecret#")
    fill_in(:user_password_confirmation, :with => "shinynewsecret#")
    submit_button.click
    expect(flash_message).to eq "Your new password has been saved, you may login below."
    expect(access_event.exception_type).to eq "user/expired_password_replacement"
    expect(access_event.login).to be_nil
    fill_in "User name", :with => "staff"
    fill_in "Password", :with => "shinynewsecret#"
    login_button.click
    sleep(0.2)
    expect(flash_message).to eq "Logged in successfully"
    click_link('Logout')
  end

  describe "disallow reuse of previous passwords" do
    before do
      Rack::Attack.enabled = false # !! multiple logins triggers rack attack
    end

    it "should disallow use of the original password" do
      login_and_change_password(login: 'password#', new_password: 'password#')
      expect(flash_message).to eq "Password cannot be reused."
    end

    it "should disallow use of the 12th most recent password" do
      login_and_change_password(login: 'password#', new_password: 'secret1*') #1
      force_expiration_of_password
      10.times do |i|
        login_and_change_password(login: "secret#{i+1}*", new_password: "secret#{i+2}*") #2
        force_expiration_of_password
      end
      login_and_change_password(login: 'secret11*', new_password: 'password#') #12
      expect(flash_message).to eq "Password cannot be reused."
    end
  end
end
