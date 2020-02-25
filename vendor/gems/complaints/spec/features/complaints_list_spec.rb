require 'rails_helper'
$:.unshift File.expand_path '../../helpers', __FILE__
require 'login_helpers'
require 'download_helpers'
require 'complaints_spec_setup_helpers'
require 'navigation_helpers'
require 'complaints_spec_helpers'
require 'upload_file_helpers'
require 'complaints_communications_spec_helpers'
require 'active_storage_helpers'
require 'area_subarea_common_helpers'
require 'rspec/expectations'

def query_hash(query_string)
  elements = query_string.gsub(/\?/,'').split('&')
  elements.inject({}) do |h, el|
    attr,val=el.split("%5B%5D=")
    if attr.present? && val.present?
      h[attr.to_sym] = h[attr.to_sym] ? h[attr.to_sym] << val.to_i : [val.to_i]
    else
      attr,val = el.split('=')
      if val.nil? || val&.match(/\d+/)
        val = val.to_i
      end
      h[attr.to_sym] = val
    end
    h
  end
end

RSpec::Matchers.define :match_hash do |expected|
  expected = expected.to_h

  match do |actual|
    key_match = actual.keys.sort == expected.keys.sort
    value_match = actual.keys.all? do |k|
      if actual[k].is_a?(Array)
        actual[k].sort == expected[k].sort
      else
        actual[k] == expected[k]
      end
    end
    key_match && value_match
  end

  failure_message do |actual|
    "expected actual: #{actual.inspect} to match expected:#{expected.inspect}"
  end
end

feature "complaints index query string", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    ComplaintStatus::Names.each{|n| ComplaintStatus.create(name: n)}
    ComplaintArea::DefaultNames.each{|n| ComplaintArea.create(name: n)}
    ComplaintArea.all.each{|area| 3.times{ ComplaintSubarea.create(name: Faker::Lorem.sentence(word_count: 2), area_id: area.id) }}
    AGENCIES.each{|a| Agency.create(name: a)}
    @norm = FactoryBot.create(:user, firstName: "Norman", lastName: "Normal")
    visit home_path('en')
    page.find('.nav #compl a.dropdown-toggle').hover
    page.find('.nav #compl .dropdown-menu #list', text: 'List').click
  end

  it "defaults to reflect default query values" do
    expect(query_hash(query_string)).to match_hash({ case_reference: 0,
                                                     city: 0,
                                                     complainant: 0,
                                                     selected_agency_id: "all",
                                                     selected_assignee_id: @user.id,
                                                     selected_status_ids: ComplaintStatus.default.map(&:id),
                                                     selected_complaint_area_ids: ComplaintArea.pluck(:id),
                                                     selected_subarea_ids: ComplaintSubarea.pluck(:id),
                                                     from: 0, to: 0, phone: 0 })
  end

  it "defaults to current user as assignee" do
    open_dropdown('Select assignee')
    sleep(0.2) # javascript
    expect( page.find(:xpath, "//li[contains(./a/div,\"#{@user.first_last_name}\")]")[:class]).to match /selected/
  end

  it "records query params in url query string" do
    select_assignee('Norman Normal')
    expect(query_hash(query_string)).to match_hash({ case_reference: 0,
                                                     city: 0,
                                                     complainant: 0,
                                                     selected_agency_id: "all",
                                                     selected_assignee_id: @norm.id,
                                                     selected_subarea_ids: ComplaintSubarea.pluck(:id),
                                                     selected_status_ids: ComplaintStatus.default.map(&:id),
                                                     selected_complaint_area_ids: ComplaintArea.pluck(:id),
                                                     from: 0, to: 0, phone: 0
                                                    })
    clear_filter_fields
    expect(query_hash(query_string)).to match_hash({ case_reference: 0,
                                                     city: 0,
                                                     complainant: 0,
                                                     selected_agency_id: "all",
                                                     selected_assignee_id: @user.id,
                                                     selected_subarea_ids: ComplaintSubarea.pluck(:id),
                                                     selected_status_ids: ComplaintStatus.default.map(&:id),
                                                     selected_complaint_area_ids: ComplaintArea.pluck(:id),
                                                     from:0, to: 0, phone: 0
                                                    })
    clear_options('Select agency')
    expect(query_hash(query_string)).to match_hash({ case_reference: 0,
                                                     city: 0,
                                                     complainant: 0,
                                                     selected_agency_id: 0,
                                                     selected_assignee_id: @user.id,
                                                     selected_subarea_ids: ComplaintSubarea.pluck(:id),
                                                     selected_status_ids: ComplaintStatus.default.map(&:id),
                                                     selected_complaint_area_ids: ComplaintArea.pluck(:id),
                                                     from: 0, to: 0, phone: 0
                                                    })
    select_all_options('Select agency')
    wait_for_ajax
    expect(query_hash(query_string)).to match_hash({ case_reference: 0,
                                                     city: 0,
                                                     complainant: 0,
                                                     selected_agency_id: "all",
                                                     selected_assignee_id: @user.id,
                                                     selected_subarea_ids: ComplaintSubarea.pluck(:id),
                                                     selected_status_ids: ComplaintStatus.default.map(&:id),
                                                     selected_complaint_area_ids: ComplaintArea.pluck(:id),
                                                     from: 0, to: 0, phone: 0
                                                    })

  end
end

feature "complaints index defaults to current user, status not closed", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    populate_database(:individual_complaint)
    FactoryBot.create(:complaint, :registered, :assigned_to => [@user, @staff_user])
    FactoryBot.create(:complaint, :closed, :assigned_to => [@user, @staff_user])
    FactoryBot.create(:complaint, :registered, :assigned_to => [@staff_user, @user])
    FactoryBot.create(:complaint, :closed, :assigned_to => [@staff_user, @user])
    visit complaints_path('en')
  end

  it "shows complaints not closed assigned to the current user" do
    expect(page.all('#complaints .complaint').length).to eq 1
    expect(page.find('#complaints .complaint .current_assignee').text).to eq @user.first_last_name
    open_dropdown('Select status')
    expect(select_option('Registered')[:class]).to include('selected')
    expect(select_option('Assessment')[:class]).to include('selected')
    expect(select_option('Investigation')[:class]).to include('selected')
  end
end

feature "complaints list", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    populate_database(:individual_complaint)
    Complaint.destroy_all
    # all these complaints are are assigned only to the "Unassigned" agency
    FactoryBot.create(:complaint, :registered, :good_governance, :assigned_to => [@user, @staff_user])
    FactoryBot.create(:complaint, :assessment, :good_governance, :assigned_to => [@user, @staff_user])
    FactoryBot.create(:complaint, :registered, :good_governance, :assigned_to => [@user, @staff_user])
    FactoryBot.create(:complaint, :investigation, :good_governance, :assigned_to => [@user, @staff_user])
    visit complaints_path('en')
  end

  it "shows complaints not closed assigned to the current user" do
    expect(page.all('#complaints .complaint').length).to eq 4
    expect(page.all('#complaints .case_reference').map{|cr| cr.text.match(/0*(\d)\/#{Date.today.strftime('%y')}/)[1].to_i }).to eq [4,3,2,1]
    #expect(page.find('#complaints .complaint .current_assignee').text).to eq @user.first_last_name
    #open_dropdown('Select status')
    #expect(select_option('Registered')[:class]).to include('selected')
    #expect(select_option('Assessment')[:class]).to include('selected')
    #expect(select_option('Investigation')[:class]).to include('selected')
  end
end

feature "complaints index", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include NavigationHelpers
  include ComplaintsSpecHelpers
  include UploadFileHelpers
  include DownloadHelpers
  include ActiveStorageHelpers
  include AreaSubareaCommonHelpers

  # most recent first
  let(:assignees) do
    Complaint.first.assigns.sort_by(&:created_at).reverse.
      collect{|a| {name: a.assignee.first_last_name,date:a.created_at.localtime.to_date.strftime("%b %-e, %Y")}}
  end

  let(:status_changes) do
    Complaint.first.status_changes.sort_by(&:change_date).reverse.
      collect{|sc| {name:sc.user.first_last_name, date:sc.change_date.localtime.to_date.strftime("%b %-e, %Y")}}
  end

  before do
    populate_database(:individual_complaint)
    visit complaints_path('en')
  end

  it "populates filter select dropdown selectors" do
    open_dropdown 'Select area'
    Mandate.all.each do |mandate|
      expect(page).to have_selector('#mandate_filter_select li a div', :text => mandate.name)
    end
    page.find('button', :text => 'Select assignee').click
    User.staff.all.each do |user|
      expect(page).to have_selector('#assignee_filter_select li a div', :text => user.first_last_name)
    end
    page.find('button', :text => 'Select agency').click
    Agency.unscoped.all.each do |agency|
      expect(page).to have_selector('#agency_filter_select li a div', :text => agency.name.strip)
    end
  end

  it "shows a list of complaints" do
    expect(page.find('h1').text).to eq "Complaints"
    expect(page).to have_selector('#complaints .complaint', :count => 1)
    # assigns are 5 days ago and 10 days ago
    # status changes are 4 days ago and 20 days ago
    expect(page.all('#complaints .complaint #timeline .timeline_event .event_label').first.text).to eq "Status change"
    open_dropdown('Select status')
    expect{ select_option('Registered').click; wait_for_ajax }.to change{ page.all('#complaints .complaint').count }.by(-1)
    expect{ select_option('Closed').click; wait_for_ajax }.to change{ page.all('#complaints .complaint').count }.by(1)
    expect(page.all('#complaints .complaint #timeline .timeline_event .event_description').first.text).to eq "Closed, No jurisdiction"

    ## reset the filter to defaults
    clear_filter_fields
    open_dropdown('Select status')
    expect(page).to have_selector("div.select li.selected")

    ## because there was a bug!
    select_option('Registered').click #deselect
    select_option('Assessment').click #deselect
    select_option('Investigation').click #deselect
    expect(page).not_to have_selector("div.select li.selected")
    clear_filter_fields
    open_dropdown('Select status')
    expect(page).to have_selector("div.select li.selected", count: 3)

    # highlight filters in effect
    expect(page.find('#complaints_controls .labels div', text: 'Status')[:class]).to include('active')
    expect(page.find('#complaints_controls .labels div', text: 'Assignee')[:class]).to include('active')
  end

  it "shows basic information for each complaint" do
    within first_complaint do
      expect(find('.current_assignee').text).to eq Complaint.first.assignees.first.first_last_name
      expect(find('.date_received').text).to eq Complaint.first.date_received.strftime("%b %-e, %Y")
      expect(all('#timeline .timeline_event').first.text).to match /#{Complaint.first.status_changes.first.event_description}/
      expect(all('#timeline .timeline_event .user_name').first.text).to match /#{Complaint.first.status_changes.first.user.first_last_name}/
      expect(all('#timeline .timeline_event .date').first.text).to match /#{Complaint.first.status_changes.first.change_date.getlocal.to_date.strftime("%b %-e, %Y")}/
      expect(all('#timeline .timeline_event').last.text).to match /#{Complaint.first.status_changes.last.event_description}/
      expect(all('#timeline .timeline_event .user_name').last.text).to match /#{Complaint.first.status_changes.last.user.first_last_name}/
      expect(all('#timeline .timeline_event .date').last.text).to match /#{Complaint.first.status_changes.last.change_date.getlocal.to_date.strftime("%b %-e, %Y")}/
      expect(find('.lastName').text).to eq Complaint.first.lastName
      expect(find('.firstName').text).to eq Complaint.first.firstName
    end
  end

  it "show each complaint to show additional information" do
    within first_complaint do
      show_complaint
    end
    expect(page_heading).to eq "Complaint, case reference: #{Complaint.first.case_reference}"
    expect(find('#city').text).to eq Complaint.first.city
    expect(find('#home_phone').text).to eq Complaint.first.home_phone
    expect(find('#complaint_details').text).to eq Complaint.first.details


    expect(page).to have_selector('.timeline_event', :count => 4)
    # assigns are 5 days ago and 10 days ago
    # status changes are 4 days ago and 20 days ago
    # events are registered, assigned, assigned, registered
    expect(all('.timeline_event .user_name')[0].text).to eq status_changes[0][:name]
    expect(all('.timeline_event .user_name')[1].text).to eq assignees[0][:name]
    expect(all('.timeline_event .user_name')[2].text).to eq assignees[1][:name]
    expect(all('.timeline_event .user_name')[3].text).to eq status_changes[1][:name]
    expect(all('.timeline_event .date')[0].text).to eq status_changes[0][:date]
    expect(all('.timeline_event .date')[1].text).to eq assignees[0][:date]
    expect(all('.timeline_event .date')[2].text).to eq assignees[1][:date]
    expect(all('.timeline_event .date')[3].text).to eq status_changes[1][:date]
    expect(all('.timeline_event .event_description')[0].text).to eq "Registered"
    expect(all('.timeline_event .event_description')[1].text).to eq assignees[0][:name]
    expect(all('.timeline_event .event_description')[2].text).to eq assignees[1][:name]
    expect(all('.timeline_event .event_description')[3].text).to eq "Registered"
    expect(all('.timeline_event .event_label')[0].text).to eq "Status change"
    expect(all('.timeline_event .event_label')[1].text).to eq "Assigned to"
    expect(all('.timeline_event .event_label')[2].text).to eq "Assigned to"
    expect(all('.timeline_event .event_label')[3].text).to eq "Initial status"

    within complaint_documents do
      Complaint.first.complaint_documents.map(&:title).each do |title|
        expect(all('.complaint_document .title').map(&:text)).to include title
      end
    end

    within human_rights_area do
      Complaint.first.complaint_subareas.human_rights.map(&:name).each do |subarea_name|
        expect(page).to have_selector('.subarea', :text => subarea_name)
      end
    end

    expect(find('#complaint_area').text).to eq "Human Rights"

    within agencies do
      expect(all('.agency').map(&:text)).to include Complaint.first.agencies.first.name
    end
  end # /it

  it "should download a complaint document file" do
    sleep(0.2)
    show_complaint
    @doc = ComplaintDocument.first
    filename = @doc.original_filename
    click_the_download_icon
    unless page.driver.instance_of?(Capybara::Selenium::Driver) # response_headers not supported
      expect(page.response_headers['Content-Type']).to eq('application/pdf')
      expect(page.response_headers['Content-Disposition']).to eq("attachment; filename=\"#{filename}\"")
    end
    expect(downloaded_file).to eq filename
  end


  it "deletes a complaint" do
    expect{delete_complaint; confirm_deletion; wait_for_ajax}.to change{ Complaint.count }.by(-1).
                                           and change{ complaints.count }.by(-1)
  end
end

feature "reloads complaints if a different assignee is selected", js: true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecSetupHelpers
  include NavigationHelpers
  include ComplaintsSpecHelpers

  let(:signed_in_user){ User.first.first_last_name }

  before do
    populate_database(:individual_complaint)
    user = FactoryBot.create(:user, firstName: "Norman", lastName: "Normal")
    @norms_complaint = FactoryBot.create(:complaint, :registered, :with_associations, :assigned_to => user)
    visit complaints_path('en')
  end

  it "should show the complaints assigned to the checked assignee" do
    select_assignee('Norman Normal')
    expect(complaints.count).to eq 1
    expect(first_complaint.find('.case_reference').text).to eq @norms_complaint.case_reference.to_s
  end

  it "should show complaints for the current user after alternative assignee setting is cleared" do
    # signed in user
    select_assignee_dropdown_should_be_checked_for(signed_in_user)
    complaints_should_be_assigned_to(signed_in_user)

    # norman
    select_assignee('Norman Normal')
    select_assignee_dropdown_should_be_checked_for('Norman Normal')
    complaints_should_be_assigned_to('Norman Normal')

    # reset to signed in user
    clear_filter_fields
    expect(complaints.count).to eq 1
    select_assignee_dropdown_should_be_checked_for(signed_in_user)
    complaints_should_be_assigned_to(signed_in_user)
    open_status_id = ComplaintStatus.where(:name => 'Registered').first.id
    expected_complaint = Complaint.with_status(open_status_id).for_assignee(User.first).first
    expect(first_complaint.find('.case_reference').text).to eq expected_complaint.case_reference.to_s

    # go back to norman
    go_back
    wait_for_ajax
    select_assignee_dropdown_should_be_checked_for('Norman Normal')
    complaints_should_be_assigned_to('Norman Normal')

    # signed_in user
    go_forward
    wait_for_ajax
    select_assignee_dropdown_should_be_checked_for(signed_in_user)
    complaints_should_be_assigned_to(signed_in_user)
  end
end

feature "selects complaints by partial match of case reference", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    create_complaint_areas
    create_agencies
    create_complaint_statuses
    create_subareas
    15.times do
      # case_refs are Cyy-1 .. Cyy-15
      FactoryBot.create(:complaint,
                        :with_associations,
                        :registered,
                        :assigned_to => User.first)
    end
    visit complaints_path(:en)
  end

  it "should return partial matches when at least two digits are entered" do
    year = Date.today.strftime('%y') 
    sequence = 12
    set_filter_controls_text_field('case_reference',"#{sequence[0]}")
    expect(complaints.count).to eq 15
    set_filter_controls_text_field('case_reference',"#{sequence}")
    expect(complaints.count).to eq 2
    set_filter_controls_text_field('case_reference',"#{sequence}-#{year[0]}")
    expect(complaints.count).to eq 1
    set_filter_controls_text_field('case_reference',"#{sequence}-#{year}")
    expect(complaints.count).to eq 1
  end
end

feature "selects complaints by partial match of complainant", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    create_complaint_areas
    create_agencies
    create_complaint_statuses
    create_subareas
    user = User.first
    ["Harry Harker", "Harriet Harker", "Adolph Champlin", "Dawn Mills"].each do |full_name|
      first, last = full_name.split
      FactoryBot.create(:complaint,
                        :with_associations,
                        :registered,
                        assigned_to: user,
                        firstName: first,
                        lastName: last)
    end
    visit complaints_path(:en)
  end

  it "should return partial matches when at least two digits are entered" do
    expect(complaints.count).to eq 4
    set_filter_controls_text_field('complainant','h')
    expect(complaints.count).to eq 3
    set_filter_controls_text_field('complainant','ha')
    expect(complaints.count).to eq 3
    set_filter_controls_text_field('complainant','harr')
    expect(complaints.count).to eq 2
    set_filter_controls_text_field('complainant','harry')
    expect(complaints.count).to eq 1
    clear_filter_fields
    expect(complaints.count).to eq 4
    set_filter_controls_text_field('complainant','Mil')
    expect(complaints.count).to eq 1
  end
end

feature "selects complaints by match of date ranges", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    create_complaint_areas
    create_subareas
    create_agencies
    user = User.first
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 1.month.ago)
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 1.month.ago.end_of_day)
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 1.month.ago.beginning_of_day)

    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 2.months.ago)
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 2.months.ago.end_of_day)
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 2.months.ago.beginning_of_day)

    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 3.months.ago)
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 3.months.ago.end_of_day)
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 3.months.ago.beginning_of_day)

    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 4.months.ago)
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 4.months.ago.end_of_day)
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, date_received: 4.months.ago.beginning_of_day)
    visit complaints_path(:en)
  end

  it "should return complaints created since the 'since' date" do
    expect(complaints.count).to eq 12
    d = Date.today.advance(months: -3)
    select_datepicker_date('#from',d.year,d.month,d.day)
    wait_for_ajax
    expect(complaints.count).to eq 9
  end

  it "should return complaints created before the 'to' date" do
    expect(complaints.count).to eq 12
    d = Date.today.advance(months: -2)
    select_datepicker_date('#to',d.year,d.month,d.day)
    wait_for_ajax
    expect(complaints.count).to eq 9
  end

  it "should return complaints created within the date range" do
    expect(complaints.count).to eq 12

    d = Date.today.advance(months: -3)
    select_datepicker_date('#from',d.year,d.month,d.day)
    wait_for_ajax
    expect(complaints.count).to eq 9

    d = Date.today.advance(months: -2)
    select_datepicker_date('#to',d.year,d.month,d.day)

    wait_for_ajax
    expect(complaints.count).to eq 6
  end
end

feature "selects complaints by partial match of city", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    create_complaint_areas
    create_subareas
    create_agencies
    user = User.first
    ['Newtown','Someplace','Amityville','Sebastopol'].each do |town|
      FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, city: town)
    end
    visit complaints_path(:en)
  end

  it "should return complaints with partial match for city" do
    expect(complaints.count).to eq 4
    set_filter_controls_text_field('city','s')
    expect(complaints.count).to eq 2

    set_filter_controls_text_field('city','st')
    expect(complaints.count).to eq 1

    clear_filter_fields
    expect(complaints.count).to eq 4
  end
end

feature "selects complaints by partial match of phone", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  before do
    create_complaint_areas
    create_subareas
    create_agencies
    user = User.first
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, home_phone: '1284235660ext99', cell_phone: '', fax: '')
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, home_phone: '312988622x34', cell_phone: '', fax: '')
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, home_phone: 'high3235', cell_phone: '', fax: '')
    FactoryBot.create(:complaint, :with_associations, :registered, agencies: [Agency.first], assigned_to: user, home_phone: '432', cell_phone: '', fax: '')
    visit complaints_path(:en)
  end

  it "should return complaints with partial match to phone" do
    expect(complaints.count).to eq 4

    set_filter_controls_text_field('phone','9')
    expect(complaints.count).to eq 2

    clear_filter_fields
    expect(complaints.count).to eq 4
  end
end

feature "selects complaints by match of area", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  context "when mandates are fully populated" do
    before do
      create_complaint_areas
      create_subareas
      create_agencies
      user = User.first
      FactoryBot.create(:complaint, :registered, :human_rights, agencies: [Agency.first], assigned_to: user)
      FactoryBot.create(:complaint, :registered, :good_governance, agencies: [Agency.first], assigned_to: user)
      FactoryBot.create(:complaint, :registered, :special_investigations_unit, agencies: [Agency.first], assigned_to: user)
      FactoryBot.create(:complaint, :registered, :corporate_services, agencies: [Agency.first], assigned_to: user)
      visit complaints_path(:en)
    end

    it "should return complaints matching the selected complaint_areas" do
      open_dropdown 'Select area'
      ComplaintArea.all.each do |area|
        expect(page).to have_selector('#area_filter_select li.selected a div', :text => area.name)
      end
      expect(complaints.count).to eq 4
      select_option('Corporate Services').click #deselect
      wait_for_ajax
      expect(complaints.count).to eq 3
      select_option('Human Rights').click #deselect
      wait_for_ajax
      expect(complaints.count).to eq 2
      select_option('Special Investigations Unit').click #deselect
      wait_for_ajax
      expect(complaints.count).to eq 1
      select_option('Good Governance').click #deselect
      wait_for_ajax
      expect(complaints.count).to eq 0
    end
  end

  context "when no complaint_areas are populated" do
    before do
      #create_complaint_areas
      create_subareas
      create_agencies
      user = User.first
      FactoryBot.create(:complaint, :with_associations, :registered, :human_rights, agencies: [Agency.first], assigned_to: user, home_phone: '1284235660ext99', cell_phone: '', fax: '')
      FactoryBot.create(:complaint, :with_associations, :registered, :good_governance, agencies: [Agency.first], assigned_to: user, home_phone: '312988622x34', cell_phone: '', fax: '')
      FactoryBot.create(:complaint, :with_associations, :registered, :special_investigations_unit, agencies: [Agency.first], assigned_to: user, home_phone: 'high3235', cell_phone: '', fax: '')
      FactoryBot.create(:complaint, :with_associations, :registered, :corporate_services, agencies: [Agency.first], assigned_to: user, home_phone: '432', cell_phone: '', fax: '')
      visit complaints_path(:en)
    end

    it "should return all complaints" do
      expect(complaints.count).to eq 4

      # trigger ajax request for "all" by filtering on another field and then resetting
      # not strictly necessary to filter on another field, but it makes the test more convincing
      # to change from 2-count to 4-count!
      set_filter_controls_text_field('phone','9')
      expect(complaints.count).to eq 2
      clear_filter_fields

      expect(complaints.count).to eq 4
    end
  end
end

feature "selects complaints matching the selected subarea", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  context "when subareas are fully populated" do
    before do
      create_complaint_areas
      create_agencies
      user = User.first
      siu_cb = FactoryBot.create(:complaint_subarea, :siu, name: 'foo')
      gg_cb  = FactoryBot.create(:complaint_subarea, :good_governance, name: 'bar')
      hr_cb  = FactoryBot.create(:complaint_subarea, :human_rights, name: 'baz')
      FactoryBot.create(:complaint, :registered, complaint_subareas: [gg_cb], assigned_to: user, agencies: [Agency.first])
      FactoryBot.create(:complaint, :registered, complaint_subareas: [siu_cb],  assigned_to: user, agencies: [Agency.first])
      FactoryBot.create(:complaint, :registered, complaint_subareas: [hr_cb],  assigned_to: user, agencies: [Agency.first])
      visit complaints_path(:en)
    end

    it "should return complaints based on selected subarea" do
      open_dropdown('Select complaint basis')
      expect(select_option('foo')[:class]).to include('selected')
      expect(complaints.count).to eq 3
      select_option('foo').click # deselect
      wait_for_ajax
      expect(complaints.count).to eq 2
      clear_options('Select complaint basis')
      expect(complaints.count).to eq 0
      select_all_options('Select complaint basis')
      expect(complaints.count).to eq 3
    end
  end

  context "when no subareas are populated" do
    before do
      create_complaint_areas
      create_agencies
      user = User.first
      FactoryBot.create(:complaint, :registered, assigned_to: user, agencies: [Agency.first], home_phone: '1284235660ext99', cell_phone: '', fax: '')
      FactoryBot.create(:complaint, :registered, assigned_to: user, agencies: [Agency.first], home_phone: '312588622x34', cell_phone: '', fax: '')
      FactoryBot.create(:complaint, :registered, assigned_to: user, agencies: [Agency.first], home_phone: 'high3235', cell_phone: '', fax: '')
      visit complaints_path(:en)
    end

    it "should return all complaints" do
      expect(complaints.count).to eq 3

      set_filter_controls_text_field('phone','9')
      expect(complaints.count).to eq 1
      clear_filter_fields

      expect(complaints.count).to eq 3
    end
  end
end

feature "selects complaints matching selected agency(-ies)", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include ComplaintsSpecHelpers
  include ComplaintsSpecSetupHelpers

  context "when agencies are fully populated" do
    before do
      create_complaint_areas
      create_agencies
      create_subareas
      user = User.first
      cc = FactoryBot.create(:complaint, :with_associations, :registered, assigned_to: user)
      cc.agencies = [Agency.first]
      cc = FactoryBot.create(:complaint, :with_associations, :registered, assigned_to: user)
      cc.agencies = [Agency.second]
      cc = FactoryBot.create(:complaint, :with_associations, :registered, assigned_to: user)
      cc.agencies = [Agency.third]
      visit complaints_path(:en)
    end

    it "should return complaints based on selected agencies" do
      expect(complaints.count).to eq 3
      open_dropdown('Select agency')
      Agency.pluck(:name).each do |name|
        expect(select_option(name)[:class]).to include('selected')
      end
      select_option(Agency.first.name).click # deselect
      wait_for_ajax
      expect(complaints.count).to eq 2
      clear_options('Select agency')
      expect(complaints.count).to eq 0
      select_all_options('Select agency')
      expect(complaints.count).to eq 3
    end
  end

  context "when unassigned agencies are requested" do
    before do
      create_complaint_areas
      create_agencies
      create_subareas
      user = User.first
      @cc = FactoryBot.create(:complaint, :with_associations, :registered, assigned_to: user)
      @cc.agencies = [Agency.unscoped.find_by(name: "Unassigned")]
      cc = FactoryBot.create(:complaint, :with_associations, :registered, assigned_to: user)
      cc.agencies = [Agency.first]
      cc = FactoryBot.create(:complaint, :with_associations, :registered, assigned_to: user)
      cc.agencies = [Agency.second]
      visit complaints_path(:en)
    end

    it "should return complaints based on selected agencies" do
      expect(complaints.count).to eq 3
      open_dropdown('Select agency')
      Agency.unscoped.pluck(:name).each do |name|
        expect(select_option(name)[:class]).to include('selected')
      end
      select_option(Agency.first.name).click # deselect
      wait_for_ajax
      expect(complaints.count).to eq 2
      clear_options('select agency')
      expect(complaints.count).to eq 0
      select_all_options('Select agency')
      expect(complaints.count).to eq 3
      clear_options('select agency')
      expect(complaints.count).to eq 0
      select_option("Unassigned").click # select
      expect(complaints.count).to eq 1
    end
  end

  context "when no agencies are populated" do
    before do
      create_complaint_areas
      create_subareas
      user = User.first
      FactoryBot.create(:complaint, :with_associations, :registered, assigned_to: user, home_phone: '1284235660ext99', cell_phone: '', fax: '')
      FactoryBot.create(:complaint, :with_associations, :registered, assigned_to: user, home_phone: '312588622x34', cell_phone: '', fax: '')
      FactoryBot.create(:complaint, :with_associations, :registered, assigned_to: user, home_phone: 'high3235', cell_phone: '', fax: '')
      visit complaints_path(:en)
    end

    it "should return complaints based on selected agencies" do
      expect(complaints.count).to eq 3

      set_filter_controls_text_field('phone','9')
      expect(complaints.count).to eq 1
      clear_filter_fields

      expect(complaints.count).to eq 3
    end
  end
end
