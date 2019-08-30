require "rails_helper"
require 'login_helpers'
require 'navigation_helpers'
require 'parse_email_helpers'

feature "Manage users -- French translation", :js => true do
  include LoggedInFrAdminUserHelper # sets up logged in french admin user
  include NavigationHelpers
  include ParseEmailHelpers

  before do
    toggle_navigation_dropdown("Admin")
    select_dropdown_menu_item("Gestion des utilisateurs")
  end

  scenario "add new user, triggering french tranlation of signup email" do
    click_link('Nouvel utilisateur')
    fill_in("Prénom", :with => "Norman")
    fill_in("Nom de famille", :with => "Normal")
    fill_in("Email", :with => "norm@normco.com")
    # ensure that mail was actually sent
    expect{click_button("Conserver")}.to change { ActionMailer::Base.deliveries.count }.by(1)
    email = ActionMailer::Base.deliveries.last
    expect( email.subject ).to eq "S'il vous plaît activer votre compte #{ORGANIZATION_NAME} #{APPLICATION_NAME}"
    expect( email.to.first ).to eq "norm@normco.com"
    expect( email.from.first ).to eq NO_REPLY_EMAIL
    lines = Nokogiri::HTML(email.body.to_s).xpath(".//p").map(&:text)
    expect( addressee ).to eq "Norman Normal"
    expect( lines[1] ).to match "#{APPLICATION_NAME}"
    expect( activate_url ).to match (/\/fr\/authengine\/activate\/[0-9a-f]{40}$/) # activation code
    expect( activate_url ).to match (/^https:\/\/#{SITE_URL}/)
    expect( sender ).to match /Administrateur #{APPLICATION_NAME}/
    expect( lines[-3]).to match /Vous serez invité à sélectionner un nom de connexion et mot de passe/
  end
end
