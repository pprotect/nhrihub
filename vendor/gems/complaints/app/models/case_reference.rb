class CaseReference
  attr_accessor :ref, :year, :sequence
  def initialize(ref=nil)
    if ref
      @ref = ref
      @year, @sequence = @ref[1,8].split('-').map(&:to_i)
      @sequence = 0 if @sequence.nil? # imported malformed case ref
      @year = 00 if @year.nil? # ditto
    else
      @year = current_year
      @sequence = 0
      @ref = next_ref
    end
  end

  def <=>(other)
    [other.year, other.sequence] <=> [year,sequence]
  end

  def next_ref
    "C#{next_year}-#{next_sequence}"
  end

  def next_year
    [year,current_year].max
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
      "complaints.case_reference ~* '^C#{year}-*#{sequence}'" # postgres ~* operator is case-insensitive regex match
    end
  end
end
