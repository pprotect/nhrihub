class ComplaintMailer < ApplicationMailer
  def complaint_assignment_notification(complaint, assignee)
    @recipient = assignee
    @complaint = complaint
    @link = complaints_url('en','html',:case_reference => "#{complaint.case_reference}")
    mail
  end

end
