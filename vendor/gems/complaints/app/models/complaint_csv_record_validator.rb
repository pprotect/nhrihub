class ComplaintCsvRecordValidator
  class InvalidRecordError < StandardError
    attr_accessor :message
    def initialize
      class_name = self.class.name.split('::')[1] 
      @message = class_name.underscore.humanize
    end
  end
  class InvalidName < InvalidRecordError; end
  class InvalidDateOpened < InvalidRecordError; end
  class InvalidDateAssessed < InvalidRecordError; end
  class InvalidReferenceNumber < InvalidRecordError; end
  class InvalidDateOfAllocation < InvalidRecordError; end
  class InvalidAllocatedToUnit < InvalidRecordError; end
  #class InvalidAssessor < InvalidRecordError; end
  #class InvalidFileWithInvestigator < InvalidRecordError; end
  #class UncertainMapping < InvalidRecordError; end
  #class InvalidAct < InvalidRecordError; end
  #class InstitutionComplainedAgainsError < InvalidRecordError; end
  class DateError < InvalidRecordError; end
  #class UnrecognizedAgency < InvalidRecordError; end

  attr_accessor :complaint, :column_validation, :errors

  def initialize(complaint,column_name,ref)
    @complaint = complaint
    @column_validation = "validate_"+ column_name.downcase.gsub(/\//,' ').gsub(/\s+/,'_')
    @errors = [ref,complaint[column_name]]
  end

  def valid?
    send(column_validation)
  rescue InvalidRecordError => e
    errors << e.message
    false
  end

  def date_separator
    date_components = complaint["COMPLAINT"].split('-')
    (14..20).to_a.include? date_components[2].to_i
  end

  private
  def validate_allocated_to_unit_province
    province_names = Province.pluck(:name).map(&:downcase)
    allocated_to = complaint["ALLOCATED TO UNIT / PROVINCE"]
    valid_provincial_office = province_names.any?{|p| p==allocated_to.downcase.strip}
    kzn = allocated_to.downcase.gsub(/ /,"") == "kwazulunatal"
    valid_head_office = (allocated_to.strip =~ /ADMI?NISTRATIVE JUSTICE AND SERVICE DELIVER/) ||
                        (allocated_to.strip =~ /GOOD GOVERNANCE AND INTEGRITY/) ||
                        (allocated_to.strip =~ /PROVINCIAL INVESTIGATION AND INTEGRATION/)
    understood_but_not_appropriate = (allocated_to == "REFERRAL") || (allocated_to.strip == "REJECTION") || (allocated_to =~ /DUPLICATE/ ) || (allocated_to =~ /NON JURISDICTION/)
    provincial_ggi = province_names.any?{|p| allocated_to.downcase.strip =~ /#{p}/ && allocated_to.downcase.strip=~/ggi/} || allocated_to == "KWAZULU NATAL-GGI"

    valid = valid_provincial_office || valid_head_office || kzn || provincial_ggi
    raise InvalidAllocatedToUnit unless valid
    true
  end


  def validate_date_of_allocation
    date_of_allocation = validate_date( complaint["DATE OF ALLOCATION"] )
  rescue DateError
    raise InvalidDateOfAllocation
  end

  def validate_date_assessed
    date_assessed = validate_date( complaint["DATE ASSESSED"] )
  rescue DateError
    raise InvalidDateAssessed
  end

  def validate_date(date_string)
    day, month, year = date_string.split('.')&.map(&:to_i)
    valid_day = [*1..31].include? day
    valid_month = [*1..12].include? month
    valid_year = [*18..20].include? year
    if valid_day && valid_month && valid_year
      return Date.new(year+2000, month, day)
    else
      raise DateError
    end
  rescue ArgumentError # Date.new exception
    raise DateError
  end

  def validate_date_opened
    date_opened = validate_date( complaint["DATE OPENED"] )
    true
  rescue DateError
    raise InvalidDateOpened
  end

  def validate_reference_number
    reference_number = complaint["REFERENCE NUMBER"]
    reference_number_re = /^\d{6}\/(16|17|18|19|20)$/
    valid = reference_number=~reference_number_re
    raise InvalidReferenceNumber unless valid
    valid
  end

  def validate_complaint
    name = complaint["COMPLAINT"].gsub(/\./,'').strip
    titles = /(DR\.?|DOCTOR|PROF\.?|CLLR\.?|ADV\.?|REV\.?|)/
    if name=~/KNOTT/
      debugger
    end
    if name=~titles
      name = name.gsub(titles,'').strip
    end
    long_initials = '([a-zA-Z]{1,3}|\w\s\w)'
    short_initials = '([a-zA-Z]{1,2}|\w\s\w)'
    name_snippets = '(\S*|VAN\s\S*|DE\s\S*|VAN\sDER\s\S*|VAN\sDEN\s\S*|DA\s\S*|DER\s\S*|DU\s\S*|LE\s\S*)'
    name_initials_re = /^#{name_snippets}\s{1,2}#{long_initials}$/
    initials_name_re = /^#{short_initials}\s{1,2}#{name_snippets}$/
    case name
    when initials_name_re
      initials, name = $1, $2
      return true
    when name_initials_re
      initials, name = $2, $1
      return true
    else
      raise InvalidName
    end
  end
end
