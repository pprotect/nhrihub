require 'levenshtein'

class ComplaintCsvRecordValidator
  class InvalidRecordError < StandardError
    attr_accessor :message
    def initialize(message = nil)
      class_name = self.class.name.split('::')[1]
      @message = message ? message : class_name.underscore.humanize
    end
  end
  class InvalidName < InvalidRecordError; end
  class InvalidDateOpened < InvalidRecordError; end
  class InvalidDateAssessed < InvalidRecordError; end
  class InvalidReferenceNumber < InvalidRecordError; end
  class InvalidDateOfAllocation < InvalidRecordError; end
  class InvalidAllocatedToUnit < InvalidRecordError; end
  class InvalidAssessor < InvalidRecordError; end
  class NotRelevantForCma < InvalidRecordError; end
  #class InvalidFileWithInvestigator < InvalidRecordError; end
  class UncertainMapping < InvalidRecordError; end
  class InvalidAct < InvalidRecordError; end
  class InstitutionComplainedAgainsError < InvalidRecordError; end
  class DateError < InvalidRecordError; end
  class UnrecognizedAgency < InvalidRecordError
    def initialize(messages)
      super messages.join(', ')
    end
  end
  class AgencyNotSpecified < InvalidRecordError; end
  class UnrecognizedDistrict < InvalidRecordError; end
  class UnknownMunicipality < InvalidRecordError; end

  attr_accessor :complaint, :column_validation, :errors, :ref, :value, :agency_names, :district_names, :branch_information, :metro, :muni, :local, :provincial_gov, :province, :regional_names

  ProvinceAbbreviations = { "GP"=>"Gauteng", "MP"=>"Mpumalanga", "NW"=>"North West", "WC"=>"Western Cape",
                            "LP"=>"Limpopo", "FS"=>"Free State", "NC"=>"Northern Cape", "EC"=>"Eastern Cape",
                            "KZN"=>"KwaZulu-Natal"}

  def initialize(complaint,column_name,ref,agency_names,district_names,regional_names)
    @complaint = complaint
    @column_validation = "validate_"+ column_name.downcase.gsub(/\//,' ').gsub(/\s+/,'_')
    @ref = ref
    @errors = [ref, complaint[column_name]]
    @agency_names = agency_names
    @district_names = district_names
    @regional_names = regional_names
  end

  def valid?
    send(column_validation)
  rescue InvalidRecordError => e
    errors << e.message
    false
  end

  def date_separator
    return true if complaint["COMPLAINT"].blank?
    date_components = complaint["COMPLAINT"].split('-')
    (14..20).to_a.include? date_components[2].to_i
  end

  private

  def extract_province(institution)
   if institution.match(/(\((#{ProvinceAbbreviations.keys.join('|')})\))/) # parenthesized province abbreviation
     m0,m1,m2 = $~.to_a
     institution = institution.gsub(m1,'').strip #extract the province
     province = ProvinceAbbreviations[m2] # identify province from abbreviation
   elsif institution.match(/((#{ProvinceAbbreviations.keys.map{|k| "(?:-|\s)#{k}(?:\s|$)"}.join('|')}))/) # non-parenthesized province abbreviation
     m0,m1,m2 = $~.to_a
     institution = institution.gsub(m1,'').strip #extract the province
     province = ProvinceAbbreviations[m2] # identify province from abbreviation
   end
   pattern = "(#{ProvinceAbbreviations.values.map{|p| /#{p.upcase}/ }.join('|')})" # non-parenthesized province
   if institution.match(/#{pattern}/)
     m0,m1,m2 = $~.to_a
     institution = institution.gsub(m1,'').strip #extract the province
     province = m2
   end
   [institution, province]
  end

  def extract_initials(institution)
    institution.gsub!(/KAMEELDRIFT POLICE STATION\)/, '(KAMEELDRIFT POLICE STATION)')
    # b/c sometimes the full agency is skipped
    if institution.match(/^saps ([^()]*)$/i)
      institution.gsub!(/^saps ([^()]*)$/i, 'SOUTH AFRICAN POLICE SERVICE (SAPS) (\1)')
    elsif  institution.match(/^saps (.*)$/i)
      institution.gsub!(/^saps (.*)$/i, 'SOUTH AFRICAN POLICE SERVICE (SAPS) \1')
    end

    possible_initials = institution.scan(/\(([^(]+)\)/).flatten # many institution fields include initials within parens, in addition to the full name
    possible_initials = possible_initials.reject{|pi| pi.length > 8} # arbitrary threshold, in case there's some other parenthesized text, that is too long to reasonably be initials
    agency = nil
    initials = nil
    possible_initials.each do |candidate|
      agency_match = institution =~Regexp.new(candidate.chars.map{|l| l+'\S+\s*'}.join('')) # match the full name with the initials
      agency = $~.to_a.first.titlecase.strip if agency_match
      initials = candidate if agency_match
      break if agency
    end
    if agency
      institution.gsub!(/\(#{initials}\)/,'')
      institution.gsub!(/\s+/,' ')
      institution.strip!
      [institution, agency, initials] 
    else
      [institution, nil, nil]
    end
  end

  def extract_descriptors(institution)
    self.metro = true if institution.match(/metropolitan/i)
    self.muni = true if institution.match(/municipality/i)
    self.local = true if institution.match(/local/i)
    self.provincial_gov = true if institution.match(/provincial government/i)
    if institution.match(/(metropolitan|municipality|local)/i)
      institution.gsub(/(metropolitan|municipality|local)/i,'').strip.titlecase
    else
      institution
    end
  end

  def extract_branch(institution)
    may_have_branch_info = institution.match(/(police|education|justice)/i)
    branch_info = institution.scan(/\(([^(]+)\)/).flatten
    if branch_info.length == 1 && may_have_branch_info
      branch_information = branch_info.first
    end
    institution = institution.gsub(/\(#{branch_information}\)/,'').strip
    [institution, branch_information]
  end

  def search_database(institution)
    exists = agency_names.map(&:downcase).any? do |name|
      if name=~/south african/
        Levenshtein.distance(institution.downcase, name) <=2
      else
        institution.downcase.match(/(department of )?#{name}/)
        #institution.downcase == name
      end
    end
    return [institution, exists]
  end

  def identify_institution_by_generic_pattern(institution)
    institution, province = extract_province(institution)
    institution, agency, initials = extract_initials(institution)
    institution, self.branch_information = extract_branch(institution)
    institution = extract_descriptors(institution)
    [institution, province, initials, branch_information]
  end

  def identify_by_labour_pattern(institution)
    original = institution
    return [institution, false] unless institution.match(/LABOUR/)
    institution = institution.gsub(/\(/, ' (') # normalize spaces before paren
    institution = institution.gsub(/OUR-(.*)$/, 'OUR (\1)')
    institution = institution.gsub(/\s+/, ' ') # normalize spaces
    if institution.match(/^(DEPART?MENT OF LABOUR) \((.*\))$/) # starts with DEPARTMENT OF LABOUR
      m0, m1, m2 = $~.to_a
      return ["DEPARTMENT OF LABOUR", true, m2]
    elsif institution.match(/(.*)\(DEPART?MENT OF LABOUR\)/) # parens
      m0, m1 = $~.to_a
      return ["DEPARTMENT OF LABOUR", true, m1.strip]
    elsif institution.match(/^DEPARTMENT OF LABOUR$/)
      return ["DEPARTMENT OF LABOUR", true, nil]
    else
      return [original, false, nil]
    end
  end

  def identify_by_correctional_pattern(institution)
    return [institution, false] unless institution&.match(/CORRECTIONAL/)
    institution = institution.gsub(/\(/, ' (') # normalize spaces before paren
    institution = institution.gsub(/\s+/, ' ') # normalize spaces
    if institution.match(/^(DEPARTMENT OF(?: THE)? CORRECTIONAL SERVICES?) \((.*\))$/) # starts with DEPARTMENT OF CORRECTIONAL SERVICES
      m0, m1, m2 = $~.to_a
      return ["DEPARTMENT OF CORRECTIONAL SERVICES", true, m2]
    else
      return [institution, false]
    end
  end

  def identify_by_district_pattern(institution)
    return [institution, false] if institution.match(/\(.*district.*\)/i) # when parenthesized, it's a specifity of another agency
    if district_names.any?{|dn| institution.downcase =~ /^#{dn}/} # starts with district name
      return [institution, true]
    elsif institution.match(/^\S+ district/i)
      raise UnrecognizedDistrict
    else
      return [institution, false]
    end
  end

  def identify_by_president_pattern(institution)
    if institution.match(/^presiden/i)
      return [institution, true]
    else
      return [institution, false]
    end
  end

  def identify_by_municipality_pattern(institution)
    return [institution, false] unless muni || local
    agency = institution.gsub(/municipality/i,'').strip
    agency = institution.gsub(/local/i,'').strip
    exists = agency_names.any?{|an| an.downcase == agency.downcase}
    unless exists
      lev_matches = agency_names.select{|an| Levenshtein.distance(an.downcase, agency.downcase) < 3}
      exists = lev_matches.length <=2 # one should suffice but there are two municipalites with the same name, in different provinces
    end
    if exists
      [institution, true, nil]
    else
      [institution, false, nil]
    end
  end

  def identify_by_provincial_pattern(institution)
    return [institution, false] unless institution.match(/provincial government/i)
    [province, true]
  end

  def validate_institution_complained_against
    institutions = complaint["INSTITUTION COMPLAINED AGAINST"]
    raise AgencyNotSpecified if institutions.nil?
    institutions.gsub!(/9NC\)/,'(NC)') # an occasional typo, easier to fix it than deal with the regexp failure it causes!
    self.branch_information = nil
    multiple = institutions.split('/').length > 1
    error_messages = []
    institutions.split('/').map(&:strip).each_with_index do |institution, index|
      institution, province, initials, self.branch_information = identify_institution_by_generic_pattern(institution)
      institution, component_exists = search_database(institution)
      unless component_exists
        ["labour", "correctional", "district", "president", "municipality", "provincial"].each do |key|
          institution, component_exists, self.branch_information = send("identify_by_#{key}_pattern", institution)
          break if component_exists
        end
      end
      institution = institution&.titlecase if component_exists
      File.open(Rails.root.join('test.txt'),"a"){|f| f.puts complaint["INSTITUTION COMPLAINED AGAINST"]} unless component_exists
      unless component_exists
        if !multiple
          error_messages << "Invalid agency"
        else
          i = index + 1
          error_messages << "#{i}#{i.ordinal} agency invalid"
        end
      end
    end

    raise UnrecognizedAgency.new(error_messages) unless error_messages.length.zero?
    true
  end

  def validate_not_yet_allocated_duplicate
    not_allocated = complaint["NOT YET ALLOCATED / DUPLICATE"]
    dupe = not_allocated&.match(/^duplicate.*\d{6}\/\d{2}/i)
    valid = not_allocated.blank? || dupe
    raise UncertainMapping unless valid
    true
  end

  def validate_act
    acts = Legislation.pluck(:short_name)
    act = complaint["ACT"]
    legislations = act&.scan(/(#{acts.join('|')})/)&.flatten
    valid = act.blank? || legislations&.length.to_i > 0
    raise InvalidAct unless valid
    true
  end

  def validate_recommendation_by_assessor_transfer
    recommendation = complaint["RECOMMENDATION BY ASSESSOR / TRANSFER"]
    allocated_to = complaint["ALLOCATED TO UNIT / PROVINCE"]
    return true unless allocated_to
    recommend_explains = ["REFERRAL","REJECTION","CLOSED"].any?{|s| allocated_to.strip == s}
    duplicate = !!recommendation&.match(/duplicate.*(\d{6}\/\d{2})/i)

    valid = recommendation.blank? || recommend_explains || duplicate
    raise UncertainMapping unless valid
    true
  end

  def validate_file_with_investigator
    field = complaint["FILE WITH INVESTIGATOR"]
    raise NotRelevantForCma unless field.blank?
    true
  end

  def validate_assessor
    assessor =  complaint["ASSESSOR"]
    assessor_first_name, assessor_last_name = names = assessor.split(' ') unless assessor.blank?
    #valid = assessor.blank? || User.where(firstName: assessor_first_name, lastName: assessor_last_name).exists?
    special_case = assessor == "JOHN NHLANHLA KHUMALO"
    valid = assessor.blank? || names.length == 2 || special_case
    raise InvalidAssessor unless valid
    true
  end

  def validate_allocated_to_unit_province
    province_names = ProvinceAbbreviations.values
    allocated_to = complaint["ALLOCATED TO UNIT / PROVINCE"]
    return true unless allocated_to
    valid_provincial_office = province_names.any?{|p| p.downcase==allocated_to.downcase.strip}
    valid_regional_office = regional_names.any?{|ro| allocated_to=~/#{ro}/}
    regional_names = Office.regional.pluck(:name)
    kzn = allocated_to.downcase.gsub(/ /,"") == "kwazulunatal"
    valid_head_office = (allocated_to.strip =~ /ADMI?NISTRATIVE JUSTICE AND SERVICE DELIVER/) ||
                        (allocated_to.strip =~ /GOOD GOVERNANCE AND INTEGRITY/) ||
                        (allocated_to.strip =~ /PROVINCIAL INVESTIGATION AND INTEGRATION/)
    notations = [/REFERRAL/, /REJECTION/, /DUPLICATE/, /NON JURISDICTION/, /FILE CLOSED/]
    understood_but_not_appropriate =  allocated_to.match(/(#{notations.join('|')})/)
    provincial_ggi = province_names.any?{|p| allocated_to.downcase.strip =~ /#{p}/ && allocated_to.downcase.strip=~/ggi/} || allocated_to == "KWAZULU NATAL-GGI"

    valid = valid_provincial_office || valid_regional_office || valid_head_office || understood_but_not_appropriate || kzn || provincial_ggi
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
    date_string.gsub!(/\.{2}/,'.') # fix a typo that occurs a few times
    date_string.gsub!(/O/,'0') # ditto
    date_string.gsub!(/\//,'.') # ditto
    day, month, year = date_string.split('.')&.map(&:to_i)
    valid_day = [*1..31].include? day
    valid_month = [*1..12].include? month
    valid_year = [*15..20,*2015..2020].include? year
    if valid_day && valid_month && valid_year
      year = year%2000 # some entries include 20yy and some do not
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
    reference_number = complaint["REFERENCE NUMBER"].strip
    reference_number.gsub!(Regexp.union(ProvinceAbbreviations.keys.map{|k| Regexp.new("\\(?#{k}\\)?")}),'') # may or may not be parenthesized
    reference_number.gsub!(/o/i,'0')
    reference_number.gsub!(/\(?duplicate.* \d{6}\/\d{2}\)?/i,'')
    reference_number.strip!
    reference_number_re = /^\d{6}\/(16|17|18|19|20)$/
    valid = reference_number=~reference_number_re
    raise InvalidReferenceNumber unless valid
    valid
  end

  def validate_complaint
    name = complaint["COMPLAINT"].gsub(/\./,'').strip
    titles = /(^DR\.?|DOCTOR|PROF\.?|CLLR\.?|ADV\.?|REV\.?|)/
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
