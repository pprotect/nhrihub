class DuplicateComplaint < Complaint
  # it's a hack in order not to set type=DuplicateComplaint as a scope in queries
  # b/c the Complaint table has a type field and so STI is invoked
  self.inheritance_column = :_type_disabled

  def as_json(options = {})
    options = {only: [:case_reference, :id], methods: [:url]}
    super(options)
  end

  def self.possible_duplicates(params)
    agency_match = with_any_agencies_matching(params[:agency_ids]).sort_by(&:case_reference)
    source = params[:type]
    complainant_match = send(:"with_duplicate_#{source}_complainant",params)
    { complainant_match: complainant_match, agency_match: agency_match }
  end
end
