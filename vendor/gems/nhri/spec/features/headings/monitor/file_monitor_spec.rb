require 'rails_helper'
require 'login_helpers'
require 'download_helpers'
$:.unshift Nhri::Engine.root.join('spec', 'helpers')
require 'headings/indicator_file_monitor_spec_helpers'
require 'headings/indicator_monitor_spec_common_helpers'
require 'headings/indicator_file_monitor_spec_setup_helpers'
require 'upload_file_helpers'

feature "monitors behaviour when indicator is configured to monitor with file format, with no file present", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include IndicatorFileMonitorSpecHelpers
  include IndicatorMonitorSpecCommonHelpers
  include IndicatorsUnpopulatedFileMonitorSpecSetupHelpers
  include UploadFileHelpers

  scenario "file information and download icons should not be visible" do
    show_monitors.click
    sleep(0.3) # css transition
    expect(page.find('#selected_file').text).to be_blank
    expect(page).not_to have_selector("i#show_details")
    expect(page).not_to have_selector('.download')
  end

  scenario "file monitor icon counter should be incremented when file is uploaded" do
    expect( monitor_icon_count ).to eq 0
    show_monitors.click
    sleep(0.3) # css transition
    page.attach_file("monitor_file", upload_document, :visible => false)
    expect{ save_monitor.click; wait_for_ajax }.to change{Nhri::FileMonitor.count}.from(0).to(1)
    close_monitors_modal
    expect( monitor_icon_count ).to eq 1
  end

  scenario "file upload, then file delete, then file upload should succeed" do
    show_monitors.click
    page.attach_file("monitor_file", upload_document, :visible => false)
    expect{ save_monitor.click; wait_for_ajax }.to change{Nhri::FileMonitor.count}.from(0).to(1)
    expect( Nhri::FileMonitor.first.original_filename).to eq "first_upload_file.pdf"
    expect{ delete_monitor.click; confirm_deletion; wait_for_ajax }.to change{Nhri::FileMonitor.count}.from(1).to(0)
    wait_until_delete_confirmation_overlay_is_removed
    page.attach_file("monitor_file", upload_document1, :visible => false)
    expect(selected_file).to eq "first_upload_file1.pdf"
    expect{ save_monitor.click; wait_for_ajax }.to change{Nhri::FileMonitor.count}.from(0).to(1)
    expect( Nhri::FileMonitor.first.original_filename).to eq "first_upload_file1.pdf"
  end

  # b/c there was a bug!
  scenario "file select, then remove selection, then click upload should give warning and no upload" do
    show_monitors.click
    expect(file_upload_button[:disabled]).to eq "disabled"
    page.attach_file("monitor_file", upload_document, :visible => false)
    expect(file_upload_button[:disabled]).to be_nil
    expect(selected_file).to eq "first_upload_file.pdf"
    deselect_file
    expect(selected_file).to be_blank
    expect(file_upload_button[:disabled]).to eq "disabled"
  end

end

feature "monitors behaviour when indicator is configured to monitor with file format", :js => true do
  include LoggedInEnAdminUserHelper # sets up logged in admin user
  include IndicatorFileMonitorSpecHelpers
  include IndicatorMonitorSpecCommonHelpers
  include IndicatorsFileMonitorSpecSetupHelpers
  include UploadFileHelpers
  include DownloadHelpers

  scenario "update the file of the existing monitor" do
    expect(page).to have_selector('h4', :text => "Monitor: File")
    expect(page).to have_selector('.template-upload #filename', :text => Nhri::FileMonitor.first.original_filename)
    page.attach_file("monitor_file", upload_document, :visible => false)
    expect(page).to have_selector('#selected_file', :text => 'first_upload_file.pdf')
    expect{ save_monitor.click; wait_for_ajax }.not_to change{Nhri::FileMonitor.count}
    expect(Nhri::FileMonitor.first.original_filename).to eq 'first_upload_file.pdf'
    expect(page.find('#filename').text).to eq 'first_upload_file.pdf'
    hover_over_info_icon
    expect(file_size).to eq "7.76 KB"
    expect(author).to eq @user.first_last_name
  end

  scenario "update the file with unpermitted file type" do
    page.attach_file("monitor_file", upload_image, :visible => false)
    expect(page).to have_selector('#selected_file', :text => 'first_upload_image_file.png')
    expect(page).to have_selector('#original_type_error', :text => "Unpermitted file type")
    expect{ save_monitor.click; wait_for_ajax }.not_to change{Nhri::FileMonitor.first.file.key}
    deselect_file
    expect(page).not_to have_selector('#selected_file', :text => 'first_upload_image_file.png')
    expect(page).not_to have_selector('#original_type_error', :text => "Unpermitted file type")
    # after deselecting, should then be able to re-select a file:
    page.attach_file("monitor_file", upload_image, :visible => false)
    expect(page).to have_selector('#selected_file', :text => 'first_upload_image_file.png')
    expect(page).to have_selector('#original_type_error', :text => "Unpermitted file type")
  end

  scenario "try to upload without selecting a file" do
    expect{ save_monitor.click; wait_for_ajax }.not_to change{Nhri::FileMonitor.first.file.key}
    expect(page).to have_css('#file_error', :text => "You must select a file")
  end

  scenario "update the file with file exceeding permitted file size" do
    page.attach_file("monitor_file", big_upload_document, :visible => false)
    expect(page).to have_selector('#selected_file', :text => 'big_upload_file.pdf')
    expect(page).to have_css('#filesize_error', :text => "File is too large")
    expect{ save_monitor.click; wait_for_ajax }.not_to change{Nhri::FileMonitor.first.file.key}
  end

  scenario "closing the monitor modal resets the selected file" do
    page.attach_file("monitor_file", upload_document, :visible => false)
    expect(page).to have_selector('#selected_file', :text => 'first_upload_file.pdf')
    close_monitors_modal
    show_monitors.click
    # wait_for_modal_open
    expect(page).not_to have_selector('#selected_file', :text => 'first_upload_file.pdf')
  end

  scenario "download the monitor file" do
    click_the_download_icon
    filename = Nhri::FileMonitor.first.original_filename
    unless page.driver.instance_of?(Capybara::Selenium::Driver) # response_headers not supported
      expect(page.response_headers['Content-Type']).to eq('application/msword')
      expect(page.response_headers['Content-Disposition']).to eq("attachment; filename=\"#{filename}\"")
    end
    expect(downloaded_file).to eq filename
  end

  scenario "delete a monitor" do
    expect( monitor_icon_count ).to eq 1
    expect{ delete_monitor.click; confirm_deletion; wait_for_ajax }.to change{Nhri::FileMonitor.count}.by(-1)
    close_monitors_modal
    expect( monitor_icon_count ).to eq 0
    show_monitors.click
    # wait_for_modal_open
    expect(number_of_file_monitors).to eq Nhri::FileMonitor.count
  end

end
