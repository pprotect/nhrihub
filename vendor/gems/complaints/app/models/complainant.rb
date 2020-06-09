class Complainant < ActiveRecord::Base
  has_and_belongs_to_many :complaints
  belongs_to :province

  enum id_type:         { "undefined" => 0, "passport number" => 1, "state id" => 2}, _prefix: true
  enum alt_id_type:     { "undefined" => 0, "pension number" => 1, "prison id" => 2, "other" => 3}, _prefix: true
  enum preferred_means: { "unspecified"=>0, "mail" => 1, "email" => 2, "home phone" => 3, "cell phone" => 4, "fax" => 5}

  before_save FormDataSanitize

  def as_json(options = {})
    # these fields are included in options when json: complaint is called in a controller
    if options.except(:status, :prefixes, :template, :layout).blank?
      options = { except: [:created_at, :updated_at, :occupation, :employer],
                  methods: [:alt_id_name] }
    end
    super(options)
  end

  def full_name
    [title, firstName, lastName].join(' ')
  end

  def gender_full_text
    case gender
    when "M"
      "male"
    when "F"
      "female"
    when "O"
      "other"
    else
      ""
    end
  end

  # assumed to be valid date_string, checked in client before submitting
  def dob=(date_string)
    write_attribute("dob", Date.parse(date_string)) unless date_string.nil?
  end

  def dob
    read_attribute("dob").strftime(Complaint::DateFormat) unless read_attribute("dob").blank?
  end
  alias :date_of_birth :dob

  def alt_id_name
    alt_id_type_other? ?
      alt_id_other_type :
      alt_id_type
  end

  def alt_id_name=(val)
    # noop, it's returned by the client, but not used... alt_id_type carries the data
  end

end
