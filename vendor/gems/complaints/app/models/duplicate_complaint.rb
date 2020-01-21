# this exists ONLY to provide a particular json representation
class DuplicateComplaint < Complaint
  def as_json(options = {})
    options = {only: [:case_reference]}
    super(options)
  end
end
