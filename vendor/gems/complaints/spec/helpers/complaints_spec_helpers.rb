require 'rspec/core/shared_context'
require 'application_helpers'
require 'reminders_spec_common_helpers'
require 'notes_spec_common_helpers'

module ComplaintsSpecHelpers
  extend RSpec::Core::SharedContext
  include ApplicationHelpers
  include RemindersSpecCommonHelpers
  include NotesSpecCommonHelpers

  def first_agency_selector
    page.all('.agency_select_container')[0]
  end

  def descend_selection_hierarchy_to(agency)
    select('National', from:'agencies_select')
    select('National government agencies', from: 'national_agencies_select')
    select(selected_government_agency.name, from: 'government_agencies_select')
  end

  def default_query_params
    { case_reference: "",
      city: "",
      complainant: "",
      selected_agency_id: "all",
      selected_office_id: "",
      selected_status_ids: ComplaintStatus.default.map(&:id),
      selected_complaint_area_ids: ComplaintArea.pluck(:id),
      selected_subarea_ids: ComplaintSubarea.pluck(:id),
      from: "", to: "", phone: "" }
  end

  def invalid_sa_id
    "12341234"
  end

  def valid_sa_id
    " 9001049818080 " # valid id with leading/trailing spaces
  end

  def set_filter_controls_text_field(name,value)
  # in the tests below we set ractive values directly b/c setting the
  # input values results in an ajax request for each character typed
    script = "complaints_page.set('filter_criteria.#{name}','#{value}')"
    page.execute_script(script)
    wait_for_ajax
  end

  #def add_a_communication
    #add_communication
    #expect(page).to have_selector('#new_communication')
    #within new_communication do
      #set_datepicker('new_communication_date',"May 19, 2016")
      #sleep(0.2)
      #choose("Email")
      #choose("Sent")
      #expect(page).to have_selector("#email_address")
      #fill_in("email_address", :with => "norm@normco.com")
      #add_communicant
      #page.all('input.communicant')[0].set("Harry Harker")
      #page.all(:css, 'input#email_address')[0].set("harry@acme.com")
      #fill_in("note", :with => "Some note text")
    #end
    #save_communication
  #end

  #def delete_a_communication
    #page.find("#communications .communication .delete_icon").click
    #confirm_deletion
    #wait_for_ajax
  #end

  def add_a_note
    add_note.click
    expect(page).to have_selector("#new_note #note_text")
    fill_in(:note_text, :with => "nota bene")
    save_note.click
    wait_for_ajax
    close_notes_modal
  end

  def add_a_reminder
    new_reminder_button.click
    select("one-time", :from => :reminder_reminder_type)
    page.find('#reminder_start_date_1i') # forces wait until the element is available
    select_date("Aug 19 #{Date.today.year.next}", :from => :reminder_start_date)
    select(User.first.first_last_name, :from => :reminder_user_id)
    fill_in(:reminder_text, :with => "time to check the database")
    save_reminder.click
    wait_for_ajax
    close_reminders_modal
  end

  def click_the_download_icon
    scroll_to(page.all('#complaint_documents .complaint_document .fa-cloud-download')[0]).click
  end

  def new_complaint
    page.find('.new_complaint')
  end

  def delete_complaint
    page.find('.delete_icon').click
  end

  def delete_document
    scroll_to(page.all('#complaint_documents .complaint_document i.delete_icon').first).click
  end

  def cancel_add
    find('#cancel_complaint').click
  end

  def edit_cancel
    page.find('#edit_cancel .fa-remove').click
  end

  def select_id(id)
    page.find(:xpath,".//li[./a/div/@id='#{id}']")
  end

  def select_option(name)
    page.find(:xpath, ".//li[./a/div/text()='#{name}']")
  end

  def current_status
    page.find('#current_status')
  end

  def status_changes
    page.find('#timeline')
  end

  def status
    page.find('.status')
  end

  def edit_complaint
    page.find('.actions .fa-pencil-square-o').click
  end

  #def deselect_file
    #page.find('#edit_communication #communication_documents .document i.remove').click
  #end

  def edit_first_complaint
    scroll_to(page.all('.actions .fa-pencil-square-o')[0]).click
  end

  def edit_second_complaint
    sleep(0.2) # while the first complaint edit panel is opening
    # b/c where this is used, the first complaint edit icon has been removed when this is called, so the second edit complaint is actually the first!
    edit_first_complaint
  end

  def select_male_gender
    choose('m')
  end

  def edit_save
    find('#edit_save').click
    wait_for_ajax
  end

  def check_agency(text)
    within page.find("#agencies_select") do
      check(text)
    end
  end

  def uncheck_agency(text)
    within page.find("#agencies_select") do
      uncheck(text)
    end
  end

  #def uncheck_mandate(text)
    #uncheck(text)
  #end

  def check_subarea(group, text)
    subarea_checkbox(group, text).set(true)
  end

  def uncheck_subarea(group, text)
    subarea_checkbox(group, text).set(false)
  end

  def good_governance_area
    page.find('.area', text: "Good Governance")
  end

  def human_rights_area
    page.find('.area', text: "Human Rights")
  end

  def special_investigations_unit_area
    page.find('.area', text: "Special Investigations Unit")
  end

  def save_complaint(wait = true)
    find('#save_complaint').click
    wait_for_ajax if wait
  end

  def agencies
    page.find('#agencies')
  end

  def first_complaint
    complaints[0]
  end

  def last_complaint
    complaints[-1]
  end

  def complaint_documents
    page.find('#complaint_documents')
  end

  def complaints
    page.all('#complaints .complaint')
  end

  def documents
    page.all('#complaint_documents .complaint_document')
  end

  def assignee_history
    find('#assignees')
  end

  def select_assignee(name)
    open_dropdown(@user.first_last_name)
    sleep(0.2) # javascript
    select_option(name).click
    wait_for_ajax
  end

  def show_complaint
    find('.show_complaint').click
  end

  def select_local_municipal_agency(context, name)
    within context do
      select('Local', from: 'agencies_select')
      select('Gauteng', from: 'provinces_select')
      select('Sedibeng', from: 'gauteng')
      select(name, from: 'sedibeng')
    end
  end

  def select_datepicker_date(id,year,month,day)
    #abbr_month = Date::ABBR_MONTHNAMES[month] # it's 1-indexed
    #page.execute_script("$('#{id}').datepicker('setDate','#{year}, #{abbr_month} #{day}')")
    page.execute_script("$('#{id}').datepicker('setDate','#{day}/#{month}/#{year}')")
    #page.execute_script("$('select.ui-datepicker-year').val(#{year}).trigger('change')")
    #page.execute_script("$('select.ui-datepicker-year').val(#{year})")
    #page.execute_script("$('select.ui-datepicker-month').val(#{month}).trigger('change')")
    #page.execute_script("$('select.ui-datepicker-month').val(#{month})")
    month = month -1 # js month  monthis 0-indexed
    # seems to be necessary in chrome headless... no idea why!!
    page.execute_script %Q{ $('#{id}').trigger('focus') } # trigger datepicker
    page.execute_script %Q{ $('#{id}').trigger('focus') } # trigger datepicker
    page.execute_script %Q{ $('#{id}').trigger('focus') } # trigger datepicker
    page.execute_script("target=$('#ui-datepicker-div td[data-month=#{month}][data-year=#{year}] a').filter(function(){return $(this).text()==#{day}})[0]")
    page.execute_script("$(target).trigger('click')")
  end

  def open_dropdown(name)
    control_button = page.find(:xpath, ".//div[contains(@class,'select')][./button/span[text()='#{name}']]")
    dropdown_is_open = control_button[:class].match(/open/)
    unless dropdown_is_open
      page.find("#complaints_controls button", :text => name).click
    end
  end

  def clear_options(name)
    unless page.has_selector?('#clear_all')
      open_dropdown(name)
    end
    page.find('#clear_all', visible: true).click
    wait_for_ajax
  end

  def select_all_options(name)
    unless page.has_selector?('#select_all')
      open_dropdown(name)
    end
    page.find('#select_all', visible: true).click
    wait_for_ajax
  end

  def select_assignee_dropdown_should_be_checked_for(first_last_name)
    open_dropdown(first_last_name)
    checked_assignee = page.all('li.selected a div')[0].text
    expect(checked_assignee).to eq first_last_name
  end

  def complaints_should_be_assigned_to(name)
    page.all('span.current_assignee').map(&:text).each do |assignee|
      expect(assignee).to eq (name)
    end
  end

  def open_close_memo_menu
    page.find('#status_memo_prompt').click
  end
end
