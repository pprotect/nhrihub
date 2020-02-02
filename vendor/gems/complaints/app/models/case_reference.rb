class CaseReference < ActiveRecord::Base
  belongs_to :complaint

  def self.matching(fragment)
    return no_filter if fragment.nil?
    return no_filter if fragment.blank?
    fragment = fragment.gsub(/\D/,'')
    fragment = fragment.gsub(/^0*/,'')
    fragment = "^#{fragment}"
    return where("concat(case_references.sequence,case_references.year) ~ ?", fragment) if sequence_first
    return where("concat(case_references.year, case_references.sequence) ~ ?", fragment) if year_first
  end

  def self.no_filter
    where("1=1")
  end

  def self.sequence_first
    CaseReferenceFormat.match(/.*sequence.*year/)
  end

  def self.year_first
    CaseReferenceFormat.match(/.*year.*sequence/)
  end

  def init_params
    max = self.class.max
    self.sequence = max&.next_ref&.sequence || 1
    self.year = current_year
  end

  def self.max
    sub_query = "select max(array[case_refs.year, case_refs.sequence]) from case_references as case_refs"
    query = "select * from case_references where array[case_references.year,case_references.sequence] = (#{sub_query}) limit 1;"
    find_by_sql(query).first
  end

  before_create :init_params

  def to_s
    CaseReferenceFormat%{sequence:sequence,year:year}
  end
  alias_method :as_json, :to_s

  def <=>(other)
    [other.year, other.sequence] <=> [year,sequence]
  end

  def next_ref
    self.class.new(sequence: next_sequence, year: next_year)
  end

  def next_year
    [year || 0, current_year].max # year may be nil
  end

  def current_year
    Date.today.strftime('%y').to_i
  end

  def next_sequence
    if year == current_year
      (sequence || 0) + 1
    else
      1
    end
  end
end
