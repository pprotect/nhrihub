require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'
require 'complaint_context_file_admin_spec_helpers'
require 'communication_context_file_admin_spec_helpers'
require 'file_admin_behaviour'
require 'area_subarea_admin'
require 'office_group_admin'

feature "complaint bases admin", :js => true do
  let(:area_model){ ComplaintArea }
  let(:subarea_model){ ComplaintSubarea }
  let(:admin_page){ complaint_admin_path('en') }
  it_behaves_like "area subarea admin"
end

feature "complaint file admin", :js => true do
  include ComplaintContextFileAdminSpecHelpers
  it_behaves_like "file admin"
end

feature "communication file admin", :js => true do
  include CommunicationContextFileAdminSpecHelpers
  it_behaves_like "file admin"
end

feature "legislation admin", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  scenario "none configured yet" do
    visit complaint_admin_path('en')
    expect(page).to have_selector("h4",:text=>"Legislation")
    expect(page).to have_selector('#legislations td#empty', :text => "None configured")
  end

  scenario "some legislations are configured" do
    FactoryBot.create(:legislation, :short_name => "ABC", :full_name => "Anywhere But Colma")
    visit complaint_admin_path('en')
    expect(page).to have_selector('#legislations .legislation td.short_name', :text => 'ABC')
    expect(page).to have_selector('#legislations .legislation td.full_name', :text => 'Anywhere But Colma')
  end

  scenario "add a valid legislation" do
    visit complaint_admin_path('en')
    page.find('input#legislation_short_name').set('ABC')
    page.find('input#legislation_full_name').set('Anywhere But Calaveras')
    expect{page.find('button#add_legislation').click; wait_for_ajax}.to change{Legislation.count}.from(0).to(1)
    expect(page).not_to have_selector('#legislations td#empty', :text => "None configured")
    expect(page).to have_selector('#legislations .legislation td.short_name', :text => 'ABC')
    expect(page).to have_selector('#legislations .legislation td.full_name', :text => 'Anywhere But Calaveras')
    expect(page.find('input#legislation_short_name').value).to eq ''
    expect(page.find('input#legislation_full_name').value).to eq ''
  end

  scenario "add an invalid legislation (blank name)" do
    visit complaint_admin_path('en')
    page.find('input#legislation_short_name').set('ABC')
    expect{page.find('button#add_legislation').click; wait_for_ajax}.not_to change{Legislation.count}
    expect(page).to have_selector('#full_name_error', :text => "Full name can't be blank")
    page.find('input#legislation_full_name').set('All blinkin correct')
    expect(page).not_to have_selector('#full_name_error')
  end

  scenario "add a legislation with duplicate name" do
    FactoryBot.create(:legislation, :short_name => "ABC", :full_name => "Anywhere But Colma")
    visit complaint_admin_path('en')
    page.find('input#legislation_short_name').set('abc') # case insensitive
    page.find('input#legislation_full_name').set('Anywhere But Chelmsford')
    expect{page.find('button#add_legislation').click; wait_for_ajax}.not_to change{Legislation.count}
    expect(page).to have_selector('#duplicate_legislation_error', :text => "Duplicate legislation not allowed")
    page.find('input#legislation_short_name').set('whaaat')
    expect(page).not_to have_selector('#duplicate_legislation_error')
  end

  scenario "add a legislation with duplicate full name" do
    FactoryBot.create(:legislation, :short_name => "ABC", :full_name => "Anywhere But Colma")
    visit complaint_admin_path('en')
    page.find('input#legislation_short_name').set('XYZ')
    page.find('input#legislation_full_name').set('Anywhere But colma') # case insensitive!
    expect{page.find('button#add_legislation').click; wait_for_ajax}.not_to change{Legislation.count}
    expect(page).to have_selector('#duplicate_legislation_error', :text => "Duplicate legislation not allowed")
    page.find('input#legislation_full_name').set('have a nice day')
    expect(page).not_to have_selector('#duplicate_legislation_error')
  end

  scenario "delete a legislation that is not associated with any complaint" do
    FactoryBot.create(:legislation, :short_name => "ABC", :full_name => "Anywhere But Colma")
    visit complaint_admin_path('en')
    expect{find("#legislations .legislation .delete_legislation").click; wait_for_ajax}.to change{Legislation.count}.from(1).to(0)
  end

  scenario "delete a legislation that is already associated with a complaint" do
    legislation = FactoryBot.create(:legislation, :short_name => "ABC", :full_name => "Anywhere But Colma")
    FactoryBot.create(:complaint, :legislations => [legislation])
    visit complaint_admin_path('en')
    expect{find("#legislations .legislation .delete_legislation").click; wait_for_ajax}.not_to change{Legislation.count}
    expect(page).to have_selector('.delete_disallowed_message', :text => "cannot delete a legislation that is associated with complaints")
    find('h1').click # click anywhere, 'body' doesn't seem to work anymore
    expect(page).not_to have_selector('.delete_disallowed_message')
  end
end

feature "agency admin", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
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

feature "complaint area/subarea admin", :js => true do
  let(:area_model){ ComplaintArea }
  let(:subarea_model){ ComplaintSubarea }
  let(:admin_page){ complaint_admin_path('en') }
  it_behaves_like 'area subarea admin'
end

feature "Office and OfficeGroup admin", :js => true do
  it_behaves_like "office and office group admin"
end
