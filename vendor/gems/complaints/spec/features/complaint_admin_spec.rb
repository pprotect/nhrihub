require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'
require 'complaint_context_file_admin_spec_helpers'
require 'communication_context_file_admin_spec_helpers'
require 'file_admin_behaviour'
require 'area_subarea_admin'
require 'office_group_admin'
require 'agency_admin_helpers'

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
  include AgencyAdminHelpers

  let(:gauteng_province){ Province.where(name: "Gauteng").first }
  let(:northern_cape_province){ Province.where(name: "Northern Cape").first }
  let(:kwazulu_natal_province){ Province.where(name: "KwaZulu-Natal").first }
  let(:sedibeng_district){ DistrictMunicipality.find_or_create_by(name: "Sedibeng", province_id: gauteng_province.id) }

  scenario "national government agencies are configured" do
    FactoryBot.create(:national_government_agency, name: "Department of Agriculture")
    FactoryBot.create(:national_government_institution, name: "Independent Complaints Directorate")
    FactoryBot.create(:democracy_supporting_state_institution, name: "The Auditor-General")
    visit complaint_admin_path('en')
    open_accordion('National')
    expect(page).to have_selector('.panel-heading', text: 'National Government Agencies')
    expect(page).to have_selector('.panel-heading', text: 'National Government Institutions')
    expect(page).to have_selector('.panel-heading', text: 'Democracy Supporting State Institutions')

    open_accordion('National Government Agencies')
    expect(page).to have_selector('.panel-body .agency', text: "Department of Agriculture" )

    sleep(0.5)
    open_accordion('National Government Institutions')
    expect(page).to have_selector('.panel-body .agency', text: "Independent Complaints Directorate" )

    sleep(0.5)
    open_accordion('Democracy Supporting State Institutions')
    expect(page).to have_selector('.panel-body .agency', text: "The Auditor-General" )
  end

  scenario "provincial agencies are configured" do
    FactoryBot.create(:provincial_agency, name: "Treasury", province_id: gauteng_province.id)
    FactoryBot.create(:provincial_agency, name: "Treasury", province_id: northern_cape_province.id)
    FactoryBot.create(:provincial_agency, name: "Treasury", province_id: kwazulu_natal_province.id)
    visit complaint_admin_path('en')
    open_accordion('Provincial')
    expect(page).to have_selector('.panel-heading', text: 'Gauteng')
    expect(page).to have_selector('.panel-heading', text: 'Northern Cape')
    expect(page).to have_selector('.panel-heading', text: 'KwaZulu-Natal')
  end

  scenario "local agencies are configured" do
    FactoryBot.create(:metropolitan_municipality, province_id: gauteng_province.id, name: "City of Johannesburg")
    FactoryBot.create(:local_municipality, province_id: gauteng_province.id, district_id: sedibeng_district.id , name: "Midvaal")
    visit complaint_admin_path('en')

    open_accordion('Local')
    expect(page).to have_selector('.panel-heading', text: 'Gauteng')

    sleep(0.4)
    open_accordion('Gauteng')
    expect(page).to have_selector('.panel-heading', text: 'Metropolitan Municipalities')
    expect(page).to have_selector('.panel-heading', text: 'District Municipalities')

    sleep(0.4)
    open_accordion('Metropolitan Municipalities')
    expect(page).to have_selector('.metropolitan_municipality', text: "City of Johannesburg")

    sleep(0.4)
    open_accordion('District Municipalities')
    expect(page).to have_selector('.panel-heading', text: 'Sedibeng')

    sleep(0.4)
    open_accordion('Sedibeng')
    expect(page).to have_selector('.local_municipality', text: 'Midvaal')
  end

  feature "add a national government agency" do
    before do
      FactoryBot.create(:national_government_agency, name: "Department of Agriculture")
      visit complaint_admin_path('en')
      open_accordion('National')

      sleep(0.4)
      open_accordion('National Government Agencies')
    end

    scenario "add a national government agency" do
      fill_in('new_agency', with: "Department of Rock'n'Roll")
      expect{save_agency}.to change{NationalGovernmentAgency.count}.by(1).
        and change{ agencies_list.length }.by(1)
      expect(page).to have_selector('.agency', text: "Department of Rock'n'Roll")
      expect(page.find('#new_agency').value).to be_blank
    end

    scenario "add a blank national government agency" do
      expect{save_agency}.not_to change{NationalGovernmentAgency.count}
      expect(page).to have_selector('#blank_name_error', exact_text: "Agency can't be blank")
      fill_in('new_agency', with: 'x')
      expect(page).not_to have_selector('#blank_name_error', exact_text: "Agency can't be blank")
    end

    scenario "add a duplicate national government agency" do
      fill_in('new_agency', with: "Department of Agriculture")
      expect{save_agency}.not_to change{NationalGovernmentAgency.count}
      expect(page).to have_selector('#duplicate_name_error', exact_text:  "Duplicate. Name must be unique")
      fill_in('new_agency', with: 'x')
      expect(page).not_to have_selector('#duplicate_name_error', exact_text:   "Duplicate. Name must be unique")
    end
  end

  feature "add a national government institution" do
    before do
      FactoryBot.create(:national_government_institution, name: "Department of Agriculture")
      visit complaint_admin_path('en')
      open_accordion('National')

      sleep(0.4)
      open_accordion('National Government Institutions')
    end

    scenario "add a national government institution" do
      fill_in('new_agency', with: "Department of Rock'n'Roll")
      expect{save_agency}.to change{NationalGovernmentInstitution.count}.by(1).
        and change{ agencies_list.length }.by(1)
      expect(page).to have_selector('.agency', text: "Department of Rock'n'Roll")
    end
  end

  feature "add a democracy-supporting institution" do
    before do
      FactoryBot.create(:democracy_supporting_state_institution , name: "Department of Agriculture")
      visit complaint_admin_path('en')
      open_accordion('National')

      sleep(0.4)
      open_accordion('Democracy Supporting State Institutions')
    end

    scenario "add a democracy-supporting institution" do
      fill_in('new_agency', with: "Department of Rock'n'Roll")
      expect{save_agency}.to change{DemocracySupportingStateInstitution.count}.by(1).
        and change{ agencies_list.length }.by(1)
      expect(page).to have_selector('.agency', text: "Department of Rock'n'Roll")
    end
  end

  feature "add a provincial agency" do
    before do
      FactoryBot.create(:provincial_agency, province_id: gauteng_province.id, name: "Department of Agriculture")
      visit complaint_admin_path('en')
      open_accordion('Provincial')

      sleep(0.4)
      open_accordion('Gauteng')
    end

    scenario "add a provincial agency" do
      fill_in('new_agency', with: "Department of Rock'n'Roll")
      expect{save_agency}.to change{ProvincialAgency.count}.by(1).
        and change{ agencies_list.length }.by(1)
      expect(page).to have_selector('.agency', text: "Department of Rock'n'Roll")
    end
  end

  feature "add a metropolitan municipality" do
    before do
      FactoryBot.create(:metropolitan_municipality, province_id: gauteng_province.id, name: "Caesaromagus")
      visit complaint_admin_path('en')
      open_accordion('Local')

      sleep(0.4)
      open_accordion('Gauteng')

      sleep(0.4)
      open_accordion('Metropolitan Municipalities')
    end

    scenario "add a metropolitan municipality" do
      fill_in('new_agency', with: "Camulodunum")
      expect{save_agency}.to change{MetropolitanMunicipality.count}.by(1).
        and change{ agencies_list.length }.by(1)
      expect(page).to have_selector('.agency', text: "Camulodunum")
    end
  end

  feature "add a local municipality" do
    before do
      FactoryBot.create(:local_municipality, district_id: sedibeng_district.id, name: "Caesaromagus")
      visit complaint_admin_path('en')
      open_accordion('Local')

      sleep(0.4)
      open_accordion('Gauteng')

      sleep(0.4)
      open_accordion('District Municipalities')

      sleep(0.4)
      open_accordion('Sedibeng')
    end

    scenario "add a local municipality" do
      fill_in('new_agency', with: "Camulodunum")
      expect{save_agency}.to change{LocalMunicipality.count}.by(1).
        and change{ agencies_list.length }.by(1)
      expect(page).to have_selector('.agency', text: "Camulodunum")
    end
  end

  #scenario "add an invalid agency (blank name)" do
  #visit complaint_admin_path('en')
  #page.find('form#new_agency input#agency_name').set('ABC')
  #expect{page.find('button#add_agency').click; wait_for_ajax}.not_to change{Agency.count}
  #expect(page).to have_selector('#invalid_agency_error', :text => "fields cannot be blank")
  #page.find('form#new_agency input#agency_full_name').click
  #expect(page).not_to have_selector('#invalid_agency_error')
  #end

  #scenario "add an agency with duplicate name" do
  #FactoryBot.create(:agency, :name => "ABC", :full_name => "Anywhere But Colma")
  #visit complaint_admin_path('en')
  #page.find('form#new_agency input#agency_name').set('abc') # case insensitive
  #page.find('form#new_agency input#agency_full_name').set('Anywhere But Chelmsford')
  #expect{page.find('button#add_agency').click; wait_for_ajax}.not_to change{Agency.count}
  #expect(page).to have_selector('#duplicate_agency_error', :text => "duplicate agency not allowed")
  #page.find('form#new_agency input#agency_name').click
  #expect(page).not_to have_selector('#duplicate_agency_error')
  #end

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
