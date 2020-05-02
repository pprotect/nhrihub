require 'rspec/core/shared_context'

module ComplaintsCommunicationsSpecHelpers
  extend RSpec::Core::SharedContext

  def close_communications_modal
    page.find("button.close").click
  end

  def communication_icon
    page.all(".fa-comments-o")[0]
  end

  def remove_last_communicant
    page.all(:xpath, ".//div[contains(@class,'new_communicant')]")[-1].find('i.remove_communicant').click
  end

  def remove_second_communicant
    page.all(:xpath, ".//div[contains(@class,'new_communicant')]")[1].find('i.remove_communicant').click
  end

  def add_communicant
    page.find('#add_communicant').click
  end

  def new_communication
    page.find('#new_communication')
  end

  def add_communication
    page.find('#add_communication').click
  end

  def cancel_add
    page.find('#new_communication #cancel_communication').click
  end

  def set_datepicker(id,date)
    # why 3x focus? dunno!
    page.execute_script %Q{ $('##{id}').trigger('focus') } # trigger datepicker
    page.execute_script %Q{ $('##{id}').trigger('focus') } # trigger datepicker
    page.execute_script %Q{ $('##{id}').trigger('focus') } # trigger datepicker
    page.execute_script %Q{ $('##{id}').datepicker('setDate','#{date}') }
    page.execute_script %Q{ $('##{id}').datepicker('hide') } # trigger the onClose handler
  end

  def communications
    page.all('#communications .communication')
  end

  def save_communication
    page.find("#save_communication").click
    wait_for_ajax
  end

  def delete_communication
    page.all('#communications .communication .delete .delete_icon')[0].click
    wait_for_ajax
  end

  def click_the_note_icon
    page.find('.note .note_icon').click
  end

  def local_offset
    Time.now.zone # the zone string for the machine on which the test is running
    #(Time.zone.utc_offset/60/60).to_s
    #(DateTime.now.utc_offset/60/60).to_s
  end

  def remove_first_document
    page.all('.document .remove')[0].click
  end

  def edit_communication
    expect(page).to have_selector (".communication .fa-pencil-square-o")
    page.all(".communication .fa-pencil-square-o")[0].click
  end

  def edit_save
    page.all(".communication .fa-check")[0].click
  end

  def dismiss_the_note_modal
    page.find('#single_note button.close').click
  end

  def open_documents_modal
    page.find("#communications .communication .documents #show_document_modal").click
  end

  def download_document
    page.find('.communication_document_document .download i').click
  end
end
