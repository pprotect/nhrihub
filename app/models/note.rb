class Note < ActiveRecord::Base
  include ActionDispatch::Routing::PolymorphicRoutes
  include Rails.application.routes.url_helpers

  belongs_to :author, :class_name => "User", :foreign_key => :author_id
  belongs_to :editor, :class_name => "User", :foreign_key => :editor_id
  belongs_to :notable, :polymorphic => true

  default_scope ->{ order(:created_at => :desc) }

  def as_json(options = {})
    super(:methods => [:date, :author_name, :editor_name, :updated_on, :url])
  end

  def url
    #Rails.application.routes.url_helpers.corporate_services_activity_note_path(:en,notable_id,id)
    polymorphic_path([notable.namespace,notable,self], :locale => :en)
  end

  def updated_on
    created_at.localtime.to_date.to_s(:short)
  end

  def date
    created_at.localtime.to_date.to_s(:short)
  end

  def author_name
    author.first_last_name
  end

  def editor_name
    editor.first_last_name
  end
end