class CaseReference
  attr_accessor :ref, :year, :sequence

  def initialize(year=nil, sequence=nil)
    @year = year.to_i
    @sequence = sequence.to_i
  end

  def to_s
    CaseReferenceFormat%{year:year,sequence:sequence}
  end
  alias_method :as_json, :to_s

  def <=>(other)
    [other.year, other.sequence] <=> [year,sequence]
  end

  def next_ref
    self.class.new(next_year, next_sequence)
  end

  def next_year
    [year,current_year].max # year may be nil
  end

  def current_year
    Date.today.strftime('%y').to_i
  end

  def next_sequence
    if year == current_year
      sequence + 1
    else
      1
    end
  end

  def self.sql_match(case_reference_fragment)
    digits = case_reference_fragment&.delete('^0-9')
    if digits.nil? || digits.empty?
      "1=1"
    else
      match, year, sequence = digits.match(/^(\d{1,2})(\d*)/).to_a
      "complaints.case_reference ~* 'year: #{year}\\d?\\nsequence: #{sequence}'" # postgres ~* operator is case-insensitive regex match
    end
  end
end
