class ComplaintDocument < ActiveRecord::Base
  include FileConstraints

  ConfigPrefix = 'complaint_document'

  has_one_attached :file

  def as_json(options={})
    super(:except => [:updated_at, :created_at], :methods => [:url, :serialization_key])
  end

  def url
    Rails.application.routes.url_helpers.complaint_document_path(I18n.locale, id)
  end

  def self.serialization_key
    'complaint[complaint_documents_attributes][]'
  end

  def serialization_key
    self.class.serialization_key
  end

  def truncated_filename
    if original_filename.length > 50
      base, extension = original_filename.split('.');
      base.slice(0,40)+"..."+extension;
    else
      original_filename
    end
  end
end
