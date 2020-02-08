class TimelineEvent
  extend Forwardable
  include ActiveModel::AttributeAssignment
  attr_accessor :model

  def_delegators :model, :change_date, :user_name, :date, :event_description, :complaint_status, :as_json

  def initialize(model)
    @model = model
  end

end
