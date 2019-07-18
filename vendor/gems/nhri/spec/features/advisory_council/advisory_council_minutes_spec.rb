require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'
require 'download_helpers'
require 'active_storage_helpers'
$:.unshift Nhri::Engine.root.join('spec', 'helpers', 'advisory_council')
require 'advisory_council_minutes_setup_helper'
require 'advisory_council_minutes_spec_helper'

feature "advisory council minutes document", :js => true do
  include IERemoteDetector
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include NavigationHelpers
  include AdvisoryCouncilMinutesSetupHelper
  include AdvisoryCouncilMinutesSpecHelper
  include DownloadHelpers
  include ActiveStorageHelpers

  before do
    Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes.maximum_filesize = 5
    Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes.permitted_filetypes = ['pdf']
    FactoryBot.create(:advisory_council_minutes, :date => Date.new(2014,8,19).to_time.utc)
    FactoryBot.create(:advisory_council_minutes, :date => Date.new(2015,8,19).to_time.utc)
    FactoryBot.create(:advisory_council_minutes, :date => Date.new(2013,8,19).to_time.utc)
    visit nhri_advisory_council_minutes_index_path(:en)
  end

  it "should show the list sorted by date" do
    expect(page.all('#advisory_council_minutes .advisory_council_minutes').count).to eq 3
    expect(page.all('.advisory_council_minutes .title').map(&:text).map{|t| t.match(/, (.*)$/)[1]}).to eq ["2015, Aug 19", "2014, Aug 19", "2013, Aug 19"]
  end

  it "should accept and save user-entered date" do
    page.attach_file("primary_file", upload_document, :visible => false)
    page.find('#advisory_council_minutes_date').set('August 19, 2025')
    expect{upload_files_link.click; wait_for_ajax }.to change{Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes.count}.by(1)
    expect(page).to have_selector('.advisory_council_minutes', :text => 'Advisory Council Meeting Minutes, 2025, Aug 19', :count => 1)
  end

  it "should reorder the list if a date is inserted in the middle" do
    page.attach_file("primary_file", upload_document, :visible => false)
    page.find('#advisory_council_minutes_date').set('August 19, 2025')
    expect{upload_files_link.click; wait_for_ajax }.to change{Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes.count}.by(1)
    expect(page.all('.advisory_council_minutes .title').map(&:text).map{|t| t.match(/, (.*)$/)[1]}).to eq ["2025, Aug 19", "2015, Aug 19", "2014, Aug 19", "2013, Aug 19"]
  end

  it "can be deleted" do
    expect{first_delete_icon.click; confirm_deletion; wait_for_ajax}.to change{Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes.count}.by(-1).
                                               and change{stored_files_count}.by(-1).
                                               and change{page.all('.advisory_council_minutes').count}.by(-1)
  end

  it "shows information popover populated with file details" do
    @doc = Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes.first
    page.execute_script("$('div.icon.details').first().trigger('mouseenter')")
    sleep(0.2) # transition animation
    expect(page).to have_css('.fileDetails')
    expect(page.find('.popover-content .name' ).text).to         eq (@doc.original_filename)
    expect(page.find('.popover-content .size' ).text).to         match /\d+\.?\d+ KB/
    expect(page.find('.popover-content .lastModified' ).text).to eq (@doc.lastModifiedDate.to_date.to_s)
    expect(page.find('.popover-content .uploadedOn' ).text).to   eq (@doc.created_at.to_date.to_s)
    expect(page.find('.popover-content .uploadedBy' ).text).to   eq (@doc.uploaded_by.first_last_name)
    page.execute_script("$('div.icon.details').first().trigger('mouseout')")
    expect(page).not_to have_css('.fileDetails')
  end

  it "can download the saved document" do
    doc = Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes.first
    click_the_download_icon
    unless page.driver.instance_of?(Capybara::Selenium::Driver) # response_headers not supported
      expect(page.response_headers['Content-Type']).to eq('application/pdf')
      filename = doc.original_filename
      expect(page.response_headers['Content-Disposition']).to eq("attachment; filename=\"#{filename}\"")
    end
    expect(downloaded_file).to eq doc.original_filename
  end

  it "start upload before any docs have been selected" do
    upload_files_link.click
    expect(flash_message).to eq "You must first click \"Add files...\" and select file(s) to upload"
  end

end
