require "rails_helper"
require 'login_helpers'
require 'access_log_helpers'

feature "Unregistered user tries to log in", :js => true do
  include AccessLogHelpers

  scenario "navigation not available before user logs in" do
    visit "/en"
    expect(page_heading).to eq "Please log in"
    expect(page).not_to have_selector(".nav")
  end

  scenario "admin logs in" do
    visit "/en"
    fill_in "User name", :with => "admin"
    fill_in "Password", :with => "password"
    page.find('#sign_up').click

    expect(flash_message).to have_text("Your username or password is incorrect.")
    expect(page).not_to have_selector(".nav")
    expect(page_heading).to eq "Please log in"
    expect(access_event.exception_type).to eq "user/login_not_found"
    expect(access_event.login).to eq "admin"
    expect(access_event.request_ip).not_to be_nil
    expect(access_event.request_user_agent).not_to be_nil
  end
end

feature "Registered user logs in with valid credentials", :js => true do
  context "two factor authentication is required" do
    include RegisteredUserHelper
    include AccessLogHelpers

    scenario "admin logs in" do
      visit "/en"
      configure_keystore

      fill_in "User name", :with => "admin"
      fill_in "Password", :with => "password"
      login_button.click
      wait_for_authentication

      expect(flash_message).to have_text("Logged in successfully")
      expect(navigation_menu).to include("Admin")
      expect(navigation_menu).to include("Logout")
      expect(access_event.exception_type).to eq "login"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
      click_link('Logout')
      expect(access_event.exception_type).to eq "logout"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
    end

    scenario "staff member logs in", :js => true do
      visit "/en"
      configure_keystore

      fill_in "User name", :with => "staff"
      fill_in "Password", :with => "password"
      login_button.click

      expect(flash_message).to have_text("Logged in successfully")
      expect(navigation_menu).not_to include("Admin")
      expect(navigation_menu).to include("Logout")
      expect(access_event.exception_type).to eq "login"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
      click_link('Logout')
      expect(access_event.exception_type).to eq "logout"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
    end
  end

  context "two factor authentication is disabled" do
    include RegisteredUserHelper
    include AccessLogHelpers
    before do
      allow(ENV).to receive(:fetch)
      allow(ENV).to receive(:fetch).with("two_factor_authentication").and_return("disabled")
      remove_user_two_factor_authentication_credentials('admin')
      remove_user_two_factor_authentication_credentials('staff')
    end

    scenario "admin logs in" do
      visit "/en"

      fill_in "User name", :with => "admin"
      fill_in "Password", :with => "password"
      login_button.click

      expect(flash_message).to have_text("Logged in successfully")
      expect(navigation_menu).to include("Admin")
      expect(navigation_menu).to include("Logout")
      expect(access_event.exception_type).to eq "login"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
      click_link('Logout')
      expect(access_event.exception_type).to eq "logout"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
    end

    scenario "staff member logs in" do
      visit "/en"

      fill_in "User name", :with => "staff"
      fill_in "Password", :with => "password"
      login_button.click

      expect(flash_message).to have_text("Logged in successfully")
      expect(navigation_menu).not_to include("Admin")
      expect(navigation_menu).to include("Logout")
      expect(access_event.exception_type).to eq "login"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
      click_link('Logout')
      expect(access_event.exception_type).to eq "logout"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
    end

    context "when they had not previously logged-out" do
      before do
        user = User.where(:login => 'admin').first
        request = Struct.new(:user_agent, :ip)
        session = Session.create!(:user => user, :request => request.new(:user_agent => 'foo', :ip => 'something'))
      end

      scenario "admin logs in" do
        visit "/en"

        fill_in "User name", :with => "admin"
        fill_in "Password", :with => "password"
        login_button.click
        sleep(0.1) # javascript renders the flash message

        expect(flash_message).to have_text("Logged in successfully")
        expect(access_event.exception_type).to eq "logout"
        expect(access_event.request_ip).not_to be_nil
        expect(access_event.request_user_agent).not_to be_nil
      end
    end
  end
end

feature "user logs in", :js => true do
  include RegisteredUserHelper
  include AccessLogHelpers

  context "without registering their token" do
    before do
      User.where(:login => 'admin').first.update(:public_key_handle => nil)
    end

    scenario "admin logs in" do
      visit "/en"

      fill_in "User name", :with => "admin"
      fill_in "Password", :with => "password"
      login_button.click
      sleep(0.1) # javascript renders the flash message

      expect(flash_message).to eq "You must have a registered key token to log in"
      expect(access_event.exception_type).to eq "user/token_not_registered"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
    end
  end

  context "without activating their account" do
    before do
      User.where(:login => 'admin').first.update(:activated_at => nil)
    end

    scenario "admin logs in" do
      visit "/en"

      fill_in "User name", :with => "admin"
      fill_in "Password", :with => "password"
      login_button.click
      sleep(0.1) # javascript renders the flash message

      expect(flash_message).to eq "Your account is not active, please check your email for the activation code."
      expect(access_event.exception_type).to eq "user/account_not_activated"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
    end
  end

  context "when their account has been disabled" do
    before do
      User.where(:login => 'admin').first.update(:enabled => false)
    end

    scenario "admin logs in" do
      visit "/en"

      fill_in "User name", :with => "admin"
      fill_in "Password", :with => "password"
      login_button.click
      sleep(0.1) # javascript renders the flash message

      expect(flash_message).to eq "Your account has been disabled, please contact administrator."
      expect(access_event.exception_type).to eq "user/account_disabled"
      expect(access_event.request_ip).not_to be_nil
      expect(access_event.request_user_agent).not_to be_nil
    end
  end

end

feature "Registered user logs in with invalid credentials", :js => true do
  include RegisteredUserHelper
  include AccessLogHelpers
  scenario "enters bad password" do
    visit "/en"
    configure_keystore

    fill_in "User name", :with => "admin"
    fill_in "Password", :with => "badpassword"
    login_button.click

    expect(flash_message).to have_text("Your username or password is incorrect.")
    expect(page_heading).to eq "Please log in"
    expect(access_event.exception_type).to eq "user/invalid_password"
    expect(access_event.request_ip).not_to be_nil
    expect(access_event.request_user_agent).not_to be_nil
  end

  scenario "enters bad user name" do
    visit "/en"

    fill_in "User name", :with => "notavaliduser"
    fill_in "Password", :with => "password"
    login_button.click

    expect(flash_message).to have_text("Your username or password is incorrect.")
    expect(page_heading).to eq "Please log in"
    expect(page).not_to have_selector(".nav")
    expect(access_event.exception_type).to eq "user/login_not_found"
    expect(access_event.request_ip).not_to be_nil
    expect(access_event.request_user_agent).not_to be_nil
  end
end

feature "User is not logged in but tries to access a page", :js => true do
  scenario "visit a protected page" do
    visit "/en/nhri/icc"
    expect(page_heading).to eq "Please log in"
  end
end
