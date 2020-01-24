class ComplaintMailer < ApplicationMailer
  def complaint_assignment_notification(complaint, assignee)
    @recipient = assignee
    @complaint = complaint
    @link = complaint.url
    mail
  end

end
