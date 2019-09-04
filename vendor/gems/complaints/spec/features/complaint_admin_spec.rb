require 'rails_helper'
require 'login_helpers'
require 'complaint_admin_spec_helpers'
require 'navigation_helpers'
require 'complaint_context_file_admin_spec_helpers'
require 'communication_context_file_admin_spec_helpers'
require 'file_admin_behaviour'
require 'area_subarea_admin'

feature "complaint bases admin", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintAdminSpecHelpers
  it_behaves_like "area subarea admin"
end

feature "complaint file admin", :js => true do
  include ComplaintAdminSpecHelpers
  include ComplaintContextFileAdminSpecHelpers
  it_should_behave_like "file admin"
end

feature "communication file admin", :js => true do
  include ComplaintAdminSpecHelpers
  include CommunicationContextFileAdminSpecHelpers
  it_should_behave_like "file admin"
end

feature "agency admin", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintAdminSpecHelpers
  scenario "none configured yet" do
    visit complaint_admin_path('en')
    expect(page).to have_selector("h4",:text=>"Agencies")
    expect(page).to have_selector('#agencies td#empty', :text => "None configured")
  end

  scenario "some agencies are configured" do
    FactoryBot.create(:agency, :name => "ABC", :full_name => "Anywhere But Colma")
    visit complaint_admin_path('en')
    expect(page).to have_selector('#agencies .agency td.name', :text => 'ABC')
    expect(page).to have_selector('#agencies .agency td.full_name', :text => 'Anywhere But Colma')
  end

  scenario "add a valid agency" do
    visit complaint_admin_path('en')
    page.find('form#new_agency input#agency_name').set('ABC')
    page.find('form#new_agency input#agency_full_name').set('Anywhere But Calaveras')
    expect{page.find('button#add_agency').click; wait_for_ajax}.to change{Agency.count}.from(0).to(1)
    expect(page).not_to have_selector('#agencies td#empty', :text => "None configured")
    expect(page).to have_selector('#agencies .agency td.name', :text => 'ABC')
    expect(page).to have_selector('#agencies .agency td.full_name', :text => 'Anywhere But Calaveras')
    expect(page.find('form#new_agency input#agency_name').value).to eq ''
    expect(page.find('form#new_agency input#agency_full_name').value).to eq ''
  end

  scenario "add an invalid agency (blank name)" do
    visit complaint_admin_path('en')
    page.find('form#new_agency input#agency_name').set('ABC')
    expect{page.find('button#add_agency').click; wait_for_ajax}.not_to change{Agency.count}
    expect(page).to have_selector('#invalid_agency_error', :text => "fields cannot be blank")
    page.find('form#new_agency input#agency_full_name').click
    expect(page).not_to have_selector('#invalid_agency_error')
  end

  scenario "add an invalid agency (blank name)" do
    visit complaint_admin_path('en')
    page.find('form#new_agency input#agency_full_name').set('Anywhere But Chelmsford')
    expect{page.find('button#add_agency').click; wait_for_ajax}.not_to change{Agency.count}
    expect(page).to have_selector('#invalid_agency_error', :text => "fields cannot be blank")
    page.find('form#new_agency input#agency_name').click
    expect(page).not_to have_selector('#invalid_agency_error')
  end

  scenario "add an agency with duplicate name" do
    FactoryBot.create(:agency, :name => "ABC", :full_name => "Anywhere But Colma")
    visit complaint_admin_path('en')
    page.find('form#new_agency input#agency_name').set('abc') # case insensitive
    page.find('form#new_agency input#agency_full_name').set('Anywhere But Chelmsford')
    expect{page.find('button#add_agency').click; wait_for_ajax}.not_to change{Agency.count}
    expect(page).to have_selector('#duplicate_agency_error', :text => "duplicate agency not allowed")
    page.find('form#new_agency input#agency_name').click
    expect(page).not_to have_selector('#duplicate_agency_error')
  end

  scenario "add an agency with duplicate full name" do
    FactoryBot.create(:agency, :name => "ABC", :full_name => "Anywhere But Colma")
    visit complaint_admin_path('en')
    page.find('form#new_agency input#agency_name').set('XYZ')
    page.find('form#new_agency input#agency_full_name').set('Anywhere But colma') # case insensitive!
    expect{page.find('button#add_agency').click; wait_for_ajax}.not_to change{Agency.count}
    expect(page).to have_selector('#duplicate_agency_error', :text => "duplicate agency not allowed")
    page.find('form#new_agency input#agency_full_name').click
    expect(page).not_to have_selector('#duplicate_agency_error')
  end

  scenario "delete an agency that is not associated with any complaint" do
    FactoryBot.create(:agency, :name => "ABC", :full_name => "Anywhere But Colma")
    visit complaint_admin_path('en')
    expect{find("#agencies .agency .delete_agency").click; wait_for_ajax}.to change{Agency.count}.from(1).to(0)
  end

  scenario "delete an agency that is already associated with a complaint" do
    agency = FactoryBot.create(:agency, :name => "ABC", :full_name => "Anywhere But Colma")
    FactoryBot.create(:complaint, :agencies => [agency])
    visit complaint_admin_path('en')
    expect{find("#agencies .agency .delete_agency").click; wait_for_ajax}.not_to change{Agency.count}
    expect(page).to have_selector('#delete_disallowed', :text => "cannot delete an agency that is associated with complaints")
    find('h1').click # click anywhere, 'body' doesn't seem to work anymore
    expect(page).not_to have_selector('#delete_disallowed')
  end
end
