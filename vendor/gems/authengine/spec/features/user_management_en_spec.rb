require "rails_helper"
require 'application_helpers'
require 'login_helpers'
require 'navigation_helpers'
require_relative '../helpers/user_management_helpers'
require 'unactivated_user_helpers'
require 'async_helper'
require 'role_presets_helper'
require 'parse_email_helpers'

feature "Manage users", :js => true do
  include ApplicationHelpers
  include RolePresetsHelper
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include NavigationHelpers
  include UserManagementHelpers
  include AsyncHelper
  include ParseEmailHelpers

  before do
    visit '/en'
    toggle_navigation_dropdown("Admin")
    select_dropdown_menu_item("Manage users")
  end

  scenario "navigate to user manaagement page" do
    expect(page_heading).to eq "Manage users"
    expect(page_title).to eq "Manage users"
  end

  scenario "add a new user" do
    click_link('New User')
    eventually do
      expect(page_heading).to eq "Create a new user account"
      expect(page_title).to eq "Create a new user account"
    end
    fill_in("First name", :with => "Norman")
    fill_in("Last name", :with => "Normal")
    fill_in("Email", :with => "norm@normco.com")
    select("Gauteng", :from => 'user_office_id')
    # ensure that mail was actually sent
    expect{click_button("Save")}.to change { email_count }.by(1)
    expect(page_heading).to eq "Manage users"
    expect(flash_message).to eq "a registration email has been sent to Norman Normal at norm@normco.com"
    user = User.where(firstName: 'Norman', lastName: 'Normal').first

    # check the email
    expect( email.subject ).to eq "Please activate your #{ORGANIZATION_NAME} #{APPLICATION_NAME} account"
    expect( email.to.first ).to eq "norm@normco.com"
    expect( email.from.first ).to eq NO_REPLY_EMAIL
    expect( header_field('List-Unsubscribe-Post')).to eq "List-Unsubscribe=One-Click"
    expect( header_field('List-Unsubscribe')).to eq admin_unsubscribe_url(:en,user.id, user.unsubscribe_code, host: SITE_URL, protocol: :https)
    lines = Nokogiri::HTML(email.body.to_s).xpath(".//p").map(&:text)
    expect( addressee ).to eq "Norman Normal"
    expect( lines[1] ).to match "#{APPLICATION_NAME}"
    expect( activate_url ).to match (/\/en\/authengine\/activate\/[0-9a-f]{40}$/) # activation code
    expect( activate_url ).to match (/^https:\/\/#{SITE_URL}/)
    expect( sender ).to match /#{APPLICATION_NAME} administrator/
    expect( norman_normal_to_be_in_the_database ).to eq true
    expect( norman_normal_account_is_activated ).to eq false
    expect( unsubscribe_url ).to match (/\/en\/admin\/unsubscribe\/#{user.id}\/[0-9a-f]{40}$/) # unsubscribe code
  end

  scenario "add a new user and reset password before user has first logged in" do
    user = FactoryBot.create(:user, :lastName => "D'Amore")
    ActiveRecord::Base.connection.execute("update users set salt = NULL, crypted_password = NULL where users.id = #{user.id}")
    visit admin_users_path(:en)
    within user_record_for(user) do
      expect{ click_link "resend registration" }.to change{ email_count }.by 1
    end
    expect( flash_message ).to match /a registration email has been resent to #{user.first_last_name} at #{user.email}/
    expect( email.subject ).to eq "Please activate your #{ORGANIZATION_NAME} #{APPLICATION_NAME} account"
    expect( email.to.first ).to eq user.email
    expect( header_field('List-Unsubscribe-Post')).to eq "List-Unsubscribe=One-Click"
    # during resend_registration_email, the user is deleted and recreated with the same attributes
    user = User.find_by(:lastName => user.lastName, :firstName => user.firstName)
    expect( header_field('List-Unsubscribe')).to eq admin_unsubscribe_url(:en,user.id, user.unsubscribe_code, host: SITE_URL, protocol: :https)
    expect( unsubscribe_url ).to match (/\/en\/admin\/unsubscribe\/#{user.id}\/[0-9a-f]{40}$/) # unsubscribe code
  end

  scenario "show user information" do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      click_link("show")
    end
    eventually(:interval => 0.001) do # hack required due to Firefox timing
      expect(page_heading).to eq User.last.first_last_name
    end
    click_link("Back")
    eventually(:interval => 0.001) do # hack required due to Firefox timing
      expect(page_heading).to eq "Manage users"
    end
  end

  scenario "disable a user" do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      click_link("disable")
    end
    expect(page.find(:xpath, ".//tr[contains(td[3],'staff')]/td[5]").text ).to match /no/
    expect(page.find(:xpath, ".//tr[contains(td[3],'staff')]/td[6]/a").text ).to eq 'enable'
  end

  scenario "delete a user" do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      click_link("delete")
    end
    expect{confirm_deletion; sleep(1)}.to change{ page.all(".user").count}.from(2).to 1
  end

  scenario "edit roles for a user", :js => true do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      click_link("edit roles")
    end
    eventually do
      expect(page_heading).to eq "Roles for #{User.last.first_last_name}"
    end
    expect(page.all('#assigned_roles li.name').map(&:text)).to include 'staff [ remove role ]'
    page.find('#available_roles li', :text => 'intern [ assign role ]').find('a').click
    eventually do
      expect(page.all('#assigned_roles li.name').map(&:text)).to include 'intern [ remove role ]'
    end
  end

  scenario "edit roles for a user, and cancel without saving" do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      click_link("edit roles")
    end
    eventually do
      expect(page_heading).to eq "Roles for #{User.last.first_last_name}"
    end
    click_link("Back")
    eventually do
      expect(page_heading).to eq "Manage users"
    end
  end

  scenario "edit profile of a user" do
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      click_link("edit profile")
    end
    fill_in "First name", :with => "Anastacia"
    fill_in "Last name", :with => "Friesen"
    fill_in "Email", :with => "ole_medhurst@parisianschamberger.info"
    select "George", :from => "Office"
    click_button "Save"
    expect(page_heading).to eq "Manage users"
    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      expect( find(:xpath, './td[1]').text ).to eq 'Friesen, Anastacia'
    end
  end
end

feature "Edit profile of unactivated user", :js => true do
  include UnactivatedUserHelpers # creates unactivated user
  include ApplicationHelpers
  include NavigationHelpers
  include LoggedInEnAdminUserHelper # sets up logged in admin user

  before do
    visit '/en'
    toggle_navigation_dropdown("Admin")
    select_dropdown_menu_item("Manage users")
  end

  # should not be able to change the profile of an unactivated user
  # as the registration email has already been sent
  # if the email address is a problem, must delete and create new
  # TODO this doesn't work... can't disable an <a> tag with a disabled attribute... who knew?
  scenario "edit profile link should be disabled" do
    within(:xpath, ".//tr[contains(td[3],'intern')]") do
      expect(find('a', :text => "edit profile")['class']).to match /disabled/
    end

    within(:xpath, ".//tr[contains(td[3],'admin')]") do
      expect(find('a', :text => "edit profile")['class']).not_to match /disabled/
    end

    within(:xpath, ".//tr[contains(td[3],'staff')]") do
      expect(find('a', :text => "edit profile")['class']).not_to match /disabled/
    end
  end
end

feature "user account activation", :js => true do
  include UnactivatedUserHelpers # creates unactivated user
  include UserManagementHelpers
  include ParseEmailHelpers

  context "environment variable requires 2-factor authentication" do
    before do
      allow(ENV).to receive(:fetch)
      allow(ENV).to receive(:fetch).with("two_factor_authentication").and_return("enabled")
      visit '/en'
    end

    scenario "user activates account by clicking url in registration email" do
      url = email_activation_link
      visit(url)
      expect(page_heading).to match /Welcome #{User.last.first_last_name} to the #{APPLICATION_NAME}/
      fill_in(:user_login, :with => "norm")
      fill_in(:user_password, :with => "sekret*")
      fill_in(:user_password_confirmation, :with => "sekret*")
      base64_strict = /^(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$/
      base64_urlsafe = /^(?:[A-Za-z0-9+\/])*?$/
      expect{ signup }.to change{ User.last.crypted_password }.from(nil).to(/[a-f0-9]{40}/).
                                                      and change{ User.last.salt }.from(nil).to(/[a-f0-9]{40}/).
                                                      and change{ User.last.public_key }.from(nil).to(base64_strict).
                                                      and change{ User.last.public_key_handle }.from(nil).to(base64_urlsafe).
                                                      and change{ email_count }.by 1
      expect(User.last.password_start_date.to_date).to eq Date.today
      expect(flash_message).to have_text("Your account has been activated")
      expect(page_heading).to eq 'Please log in'
      # not normal action, but we test it anyway, user clicks the activation link again
      visit(url)
      #this is what the message SHOULD say TODO, fix this
      #expect(flash_message).to eq 'Your account has already been activated. You can log in below.'
      expect(flash_message).to eq 'Your account has been activated. You can log in below.'
      expect(page_heading).to eq 'Please log in'
      # not normal action, but we test it anyway, user clicks the activation link again
      url_without_activation_code = url.gsub(/[^\/]*$/,'')
      visit(url_without_activation_code )
      expect(flash_message).to eq 'Activation code not found. Please ask the database administrator to create an account for you.'
      expect(page_heading).to eq 'Please log in'
      url_with_wrong_activation_code = url.gsub(/[^\/]*$/,'abc123')
      visit url_with_wrong_activation_code
      expect(flash_message).to eq 'Activation code not found. Please contact the database administrator.'
      expect(page_heading).to eq 'Please log in'
    end

    scenario "password rules enforcement -- passwords don't match, password confirmation blank" do
      url = email_activation_link
      visit(url)
      expect(page_heading).to match /Welcome #{User.last.first_last_name} to the #{APPLICATION_NAME}/
      fill_in(:user_login, :with => "norm")
      fill_in(:user_password, :with => "abcde")
      expect{ signup; sleep(1) }.not_to change{ User.last.crypted_password }
      expect(User.last.password_start_date&.to_date).to be_nil
      expect(page).to have_selector("#message_block .warn", text: "Password confirmation doesn't match password, please try again.")
      expect(page).to have_selector("#message_block .warn", text: "Password confirmation can't be blank")
    end
  end

  context "environment variable disables 2-factor authentication" do
    before do
      allow(ENV).to receive(:fetch)
      allow(ENV).to receive(:fetch).with("two_factor_authentication").and_return("disabled")
    end

    scenario "user activates account by clicking url in registration email" do
      url = email_activation_link
      visit(url)
      expect(page_heading).to match /Welcome #{User.last.first_last_name} to the #{APPLICATION_NAME}/
      fill_in(:user_login, :with => "norm")
      fill_in(:user_password, :with => "sekret&")
      fill_in(:user_password_confirmation, :with => "sekret&")
      expect{ signup }.to change{ User.last.crypted_password }.from(nil).to(/[a-f0-9]{40}/).
                      and change{ User.last.salt }.from(nil).to(/[a-f0-9]{40}/).
                      and change{ email_count }.by 1
      expect( User.last.public_key ).to be_nil
      expect( User.last.public_key_handle ).to be_nil
      expect( User.last.password_start_date.to_date).to eq Date.today
      expect(flash_message).to have_text("Your account has been activated")
      expect(page_heading).to eq 'Please log in'
    end

    scenario "password rules enforcement -- passwords don't match, password confirmation blank" do
      url = email_activation_link
      visit(url)
      expect(page_heading).to match /Welcome #{User.last.first_last_name} to the #{APPLICATION_NAME}/
      fill_in(:user_login, :with => "norm")
      fill_in(:user_password, :with => "abcde")
      expect{ signup; sleep(1) }.not_to change{ User.last.crypted_password }
      expect( User.last.password_start_date&.to_date).to be_nil
      expect(page).to have_selector("#message_block .warn", text: "Password confirmation doesn't match password, please try again.")
      expect(page).to have_selector("#message_block .warn", text: "Password confirmation can't be blank")
    end

    scenario "password rules enforcement -- password criteria not met" do
      url = email_activation_link
      visit(url)
      expect(page_heading).to match /Welcome #{User.last.first_last_name} to the #{APPLICATION_NAME}/
      fill_in(:user_login, :with => "norm")
      fill_in(:user_password, :with => "abcde")
      fill_in(:user_password_confirmation, :with => "abcde")
      expect{ signup; sleep(1) }.not_to change{ User.last.crypted_password }
      expect( User.last.password_start_date&.to_date).to be_nil
      expect(page).to have_selector("#message_block .warn li", text: "Password is too short (minimum is 6 characters)")
      expect(page).to have_selector("#message_block .warn li", text: "Password must contain !@#%$^&*()-+<>")
    end

    scenario "password rules enforcement -- password criteria not met" do
      url = email_activation_link
      visit(url)
      expect(page_heading).to match /Welcome #{User.last.first_last_name} to the #{APPLICATION_NAME}/
      fill_in(:user_login, :with => "norm")
      fill_in(:user_password, :with => "abcd<")
      fill_in(:user_password_confirmation, :with => "abcd<")
      expect{ signup; sleep(1) }.not_to change{ User.last.crypted_password }
      expect( User.last.password_start_date&.to_date).to be_nil
      expect(page).to have_selector("#message_block .warn li", text: "Password is too short (minimum is 6 characters)")
      expect(page).not_to have_selector("#message_block .warn li", text: "Password must contain !@#%$^&*()-+<>")
    end
  end
end

#feature "user lost token replacement and registration", :js => true do
  #include LoggedInEnAdminUserHelper # logs in as admin
  #include NavigationHelpers
  #include UserManagementHelpers
  #include ParseEmailHelpers

  #before do
    #visit '/en'
    #toggle_navigation_dropdown("Admin")
    #select_dropdown_menu_item("Manage users")
  #end

  #scenario "normal operation" do
    #user = User.staff.first
    #within(:xpath, ".//tr[contains(td[3],'staff')]") do
      #expect{ click_link('lost access token') }.to change { email_count }.by 1
      #expect( header_field('List-Unsubscribe-Post')).to eq "List-Unsubscribe=One-Click"
      #user = user.reload # b/c a new unsubscribe_code is generated
      #expect( header_field('List-Unsubscribe')).to eq admin_unsubscribe_url(:en,user.id, user.unsubscribe_code, host: SITE_URL, protocol: :https)
      #expect( unsubscribe_url ).to match (/\/en\/admin\/unsubscribe\/#{user.id}\/#{user.unsubscribe_code}$/) # unsubscribe code
    #end
    #expect(page_heading).to eq "Manage users"
    #expect(flash_message).to match /A token registration email has been sent to/

    ## disable access by the lost token
    #expect( user.public_key ).to be_nil
    #expect( user.public_key_handle ).to be_nil
    #expect( user.replacement_token_registration_code ).not_to be_nil
    ## b/c otherwise the login fields will not be rendered, as another mock simulates always logged-in
    #allow_any_instance_of(Authengine::SessionsController).to receive(:logged_in?).and_return(false)
    #click_link('Logout')
    ## user whose token was lost responds to the link in the email
    #visit(replacement_token_registration_link)
    #expect(page_heading).to match /Register new token for/
    #fill_in "user_login", :with => "staff"
    #fill_in "user_password", :with => "password"
    #register_button.click
    #expect(flash_message).to eq "Your new token has been registered, you may login below."
    #user.reload
    #expect( user.public_key ).not_to be_nil
    #expect( user.public_key_handle ).not_to be_nil
    #expect( user.replacement_token_registration_code ).to be_nil
    #fill_in "User name", :with => "staff"
    #fill_in "Password", :with => "password"
    #login_button.click
    #sleep(0.2)
    #expect(flash_message).to eq "Logged in successfully"

  #end
#end
