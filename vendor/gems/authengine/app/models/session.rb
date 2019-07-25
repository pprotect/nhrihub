class Session < ActiveRecord::Base
  attr_accessor :request
  belongs_to :user

  scope :belonging_to_user, ->(user) { where("user_id like ?", user) } # use % for wildcard
  scope :logged_in_after, ->(time) { where("(login_date >= ?) or logout_date is null", time) } # pass in a time object
  scope :logged_in_before, ->(time) { where("login_date <= ?", time) } # pass in a time object

  before_save AccessLogger

  def self.create_or_update(params)
    if previous_login = where({user_id:  params[:user_id], logout_date: nil}).last
      previous_login.update(params.slice(:session_id, :request))
      session = previous_login.reload
    else
      session = create( params )
    end
  end

  def formatted_login_date
    login_date.to_formatted_s(:date_and_time)
  end

  def formatted_logout_date
    logout_date ? logout_date.to_formatted_s(:date_and_time) : ""
  end
end
