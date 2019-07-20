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
    expect(access_log_message).to have_text  "Failed login. Username 'admin' not found in database"
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
      expect(access_log_message).to have_text "Login #{@user} role(s): #{@user.roles.map(&:to_s).join(', ')}"
      click_link('Logout')
      expect(access_log_message).to have_text "Logout #{@user} role(s): #{@user.roles.map(&:to_s).join(', ')}"
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
      expect(access_log_message).to have_text "Login #{@staff_user} role(s): #{@staff_user.roles.map(&:to_s).join(', ')}"
      click_link('Logout')
      expect(access_log_message).to have_text "Logout #{@staff_user} role(s): #{@staff_user.roles.map(&:to_s).join(', ')}"
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
      expect(access_log_message).to have_text "Login #{@user} role(s): #{@user.roles.map(&:to_s).join(', ')}"
      click_link('Logout')
      expect(access_log_message).to have_text "Logout #{@user} role(s): #{@user.roles.map(&:to_s).join(', ')}"
    end

    scenario "staff member logs in" do
      visit "/en"

      fill_in "User name", :with => "staff"
      fill_in "Password", :with => "password"
      login_button.click

      expect(flash_message).to have_text("Logged in successfully")
      expect(navigation_menu).not_to include("Admin")
      expect(navigation_menu).to include("Logout")
      expect(access_log_message).to have_text "Login #{@staff_user} role(s): #{@staff_user.roles.map(&:to_s).join(', ')}"
      click_link('Logout')
      expect(access_log_message).to have_text "Logout #{@staff_user} role(s): #{@staff_user.roles.map(&:to_s).join(', ')}"
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
      expect(access_log_message).to have_text "Login attempt by #{@user}, unregistered token"
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
      expect(access_log_message).to have_text  "Login attempt by #{@user}, account not activated"
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
      expect(access_log_message).to have_text "Login attempt by #{@user}, account disabled"
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
    expect(access_log_message).to have_text  "invalid password for login: admin, user: #{@user}"
  end

  scenario "enters bad user name" do
    visit "/en"

    fill_in "User name", :with => "notavaliduser"
    fill_in "Password", :with => "password"
    login_button.click

    expect(flash_message).to have_text("Your username or password is incorrect.")
    expect(page_heading).to eq "Please log in"
    expect(page).not_to have_selector(".nav")
    expect(access_log_message).to have_text "Failed login. Username 'notavaliduser' not found in database"
  end
end

feature "User is not logged in but tries to access a page", :js => true do
  include RegisteredUserHelper
  scenario "visit a protected page" do
    visit "/en/nhri/icc"
    expect(page_heading).to eq "Please log in"
  end
end
