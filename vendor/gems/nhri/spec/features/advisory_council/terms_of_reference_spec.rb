require 'rails_helper'
require 'login_helpers'
require 'navigation_helpers'
require 'upload_file_helpers'
require 'download_helpers'
require 'active_storage_helpers'
$:.unshift Nhri::Engine.root.join('spec', 'helpers', 'advisory_council')
require 'terms_of_reference_setup_helper'
require 'terms_of_reference_spec_helper'

feature "terms of reference document", :js => true do
  include IERemoteDetector
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include NavigationHelpers
  include AdvisoryCouncilTermsOfReferenceSetupHelper
  include TermsOfReferenceSpecHelper
  include UploadFileHelpers
  include DownloadHelpers
  include ActiveStorageHelpers

  before do
    Nhri::AdvisoryCouncil::TermsOfReferenceVersion.maximum_filesize = 5
    Nhri::AdvisoryCouncil::TermsOfReferenceVersion.permitted_filetypes = ['pdf']
    FactoryBot.create(:terms_of_reference_version, :revision_major => 1, :revision_minor => 2)
    FactoryBot.create(:terms_of_reference_version, :revision_major => 3, :revision_minor => 1)
    visit nhri_advisory_council_terms_of_references_path('en')
  end

  it "should show the list sorted by revision" do
    expect(page.all('#terms_of_reference_versions .terms_of_reference_version').count).to eq 2
    expect(page.all('.terms_of_reference_version .revision').map(&:text)).to eq ["3.1", "1.2"]
  end

  it "should append the added revision to the title" do
    page.attach_file("primary_file", upload_document, :visible => false)
    expect{upload_files_link.click; wait_for_ajax}.to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.count}.by(1)
    expect(page).to have_selector('.terms_of_reference_version', :text => 'Terms of Reference, revision 4.0', :count => 1)
  end

  it "should accept and save user-entered revision" do
    page.attach_file("primary_file", upload_document, :visible => false)
    page.find('#terms_of_reference_version_revision').set('3.4')
    expect{upload_files_link.click; wait_for_ajax}.to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.count}.by(1)
    uploaded_file = Nhri::AdvisoryCouncil::TermsOfReferenceVersion.where(:revision_major => 3, :revision_minor => 4).first
    expect(File.exists?(stored_file_path(uploaded_file))).to eq true
    expect(page).to have_selector('.terms_of_reference_version', :text => 'Terms of Reference, revision 3.4', :count => 1)
  end

  it "should warn and not save duplicate revisions" do
    page.attach_file("primary_file", upload_document, :visible => false)
    page.find('#terms_of_reference_version_revision').set('3.1')
    expect{upload_files_link.click; wait_for_ajax}.not_to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.count}
    expect(page).to have_selector('#unique_revision_error', :text => "Duplicate revision not allowed")
    page.find('#terms_of_reference_version_revision').set('3.2')
    expect{upload_files_link.click; wait_for_ajax}.to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.count}.by(1)
  end

  it "should warn and not save invalid revisions" do
    page.attach_file("primary_file", upload_document, :visible => false)
    page.find('#terms_of_reference_version_revision').set('x')
    expect{upload_files_link.click; wait_for_ajax}.not_to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.count}
    expect(page).to have_selector('#revision_format_error', :text => "Invalid revision.")
  end

  it "should reorder the list if a revision is inserted in the middle" do
    page.attach_file("primary_file", upload_document, :visible => false)
    page.find('#terms_of_reference_version_revision').set('2.2')
    expect{upload_files_link.click; wait_for_ajax}.to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.count}.by(1)
    expect(page.all('.terms_of_reference_version .revision').map(&:text)).to eq ["3.1", "2.2", "1.2"]
  end

  it "saves edited revision" do
    tor = Nhri::AdvisoryCouncil::TermsOfReferenceVersion.where(:revision_major => 3).first.id
    first_edit_icon.click
    page.find('input.revision').set('5.1')
    expect{edit_save_icon.click; wait_for_ajax}.to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.find(tor).revision}.from("3.1").to("5.1")
    expect(page).to have_selector('.terms_of_reference_version', :text => 'Terms of Reference, revision 5.1', :count => 1)
  end

  it "saves edited revision and reorders list" do
    tor = Nhri::AdvisoryCouncil::TermsOfReferenceVersion.where(:revision_major => 3).first.id
    first_edit_icon.click
    page.find('input.revision').set('0.9')
    expect{edit_save_icon.click; wait_for_ajax}.to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.find(tor).revision}.from("3.1").to("0.9")
    expect(page).to have_selector('.terms_of_reference_version', :text => 'Terms of Reference, revision 0.9', :count => 1)
    expect(page.all('.terms_of_reference_version .revision').map(&:text)).to eq ["1.2", "0.9"]
  end

  it "user is warned and no save occurs if a revision is duplicated by edit" do
    first_edit_icon.click
    page.find('input.revision').set('1.2')
    expect{edit_save_icon.click; wait_for_ajax}.not_to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.first.revision}
    expect(page).to have_selector('#unique_revision_error', :text => "Duplicate revision not allowed")
  end

  it "user is warned and no save occurs if an illegal revision is entered" do
    first_edit_icon.click
    page.find('input.revision').set('x')
    expect{edit_save_icon.click; wait_for_ajax}.not_to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.first.revision}
    expect(page).to have_selector('#revision_format_error', :text => "Invalid revision.")
  end

  it "revision can be deleted" do
    expect{first_delete_icon.click; confirm_deletion; wait_for_ajax}.to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.count}.by(-1).
                                               and change{stored_files_count}.by(-1).
                                               and change{page.all('.terms_of_reference_version').count}.by(-1)
  end

  it "shows information popover populated with file details" do
    @doc = Nhri::AdvisoryCouncil::TermsOfReferenceVersion.first
    page.execute_script("$('div.icon.details').first().trigger('mouseenter')")
    expect(page).to have_css('.fileDetails')
    expect(page.find('.popover-content .name' ).text).to         eq (@doc.original_filename)
    expect(page.find('.popover-content .size' ).text).to         match /\d+\.?\d+ KB/
    expect(page.find('.popover-content .rev' ).text).to          eq (@doc.revision)
    expect(page.find('.popover-content .lastModified' ).text).to eq (@doc.lastModifiedDate.to_date.to_s)
    expect(page.find('.popover-content .uploadedOn' ).text).to   eq (@doc.created_at.to_date.to_s)
    expect(page.find('.popover-content .uploadedBy' ).text).to   eq (@doc.uploaded_by.first_last_name)
    page.execute_script("$('div.icon.details').first().trigger('mouseout')")
    expect(page).not_to have_css('.fileDetails')
  end

  it "can download the saved document" do
    doc = Nhri::AdvisoryCouncil::TermsOfReferenceVersion.first
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

  it "user is warned and no save occurs if unpermitted filetype is selected" do
    page.attach_file("primary_file", upload_image, :visible => false)
    expect(page).to have_css('.error', :text => "File type not allowed")
    expect{ upload_files_link.click; wait_for_ajax}.not_to change{Nhri::AdvisoryCouncil::TermsOfReferenceVersion.count}
  end

  it "user is warned and no save occurs if selected file exceeds permitted filesize" do
    page.attach_file("primary_file", big_upload_document, :visible => false)
    expect(page).to have_css('.error', :text => "File is too large")
    page.find(".template-upload i.cancel").click
    expect(page).not_to have_css(".files .template_upload")
  end

end
