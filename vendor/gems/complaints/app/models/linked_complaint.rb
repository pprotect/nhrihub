class LinkedComplaint < Complaint
  # it's a subclass with no sti
  self.inheritance_column = :_type_disabled

  def as_json(options = {})
    options = {only: [:id], methods: [:case_reference, :url]}
    super(options)
  end
end
