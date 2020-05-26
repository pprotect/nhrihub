class DuplicateComplaint < Complaint
  # it's a subclass with no sti
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
