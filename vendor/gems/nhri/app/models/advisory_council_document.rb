# subclassed by:
#    Nhri::AdvisoryCouncil::TermsOfReferenceVersion and
#    Nhri::AdvisoryCouncil::AdvisoryCouncilMinutes
class AdvisoryCouncilDocument < ActiveRecord::Base
  include DocumentVersioning
  include FileConstraints
  include DocumentApi

  belongs_to :user
  alias_method :uploaded_by, :user

  has_one_attached :file

  after_destroy do |doc|
    # without this, ActiveStorage naturally invokes purge_later
    # which removes the file, but the uncertain delay (later)
    # is problematic for testing
    doc.file.purge
  end

  before_save do |doc|
    doc.receives_next_major_rev if doc.revision.blank?
    doc.date = DateTime.now if doc.date.blank?
  end

  def formatted_date
    date.to_date.to_s if date
  end

  def as_json(options={})
    super(:except => [:created_at, :updated_at],
          :methods => [:title,
                       :revision,
                       :uploaded_by,
                       :formatted_modification_date,
                       :formatted_creation_date,
                       :formatted_date,
                       :formatted_filesize ] )
  end

end
