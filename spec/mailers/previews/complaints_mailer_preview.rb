class ComplaintsMailerPreview < ActionMailer::Preview
  def complaint_assignment_notification
    complaint = Complaint.first
    assignee = User.first
    ComplaintMailer.complaint_assignment_notification(complaint, assignee)
  end
end
