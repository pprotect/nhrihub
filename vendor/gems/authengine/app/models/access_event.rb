class AccessEvent < ActiveRecord::Base
  belongs_to :user

  default_scope { order( "access_events.created_at DESC") }

  def self.filtered_by(params)
    filtered_by_user(params[:user]).
      filtered_by_outcome(params[:outcome]).
      filtered_by_period(params[:period])
  end

  def self.filtered_by_period(period)
    window = case period
             when /day/
               {hours: -24}
             when /week/
               {days: -7}
             when /month/
               {months: -1}
             when /year/
               {years: -1}
             else
               {years: -100}
             end
    where('access_events.created_at >= :window',{:window => DateTime.now.advance(window)} )
  end

  def self.filtered_by_user(user_id)
    if user_id.blank? || user_id=='all'
      all
    else
      joins(:user).where(users: {id: user_id})
    end
  end

  def self.filtered_by_outcome(outcome)
    case outcome
    when 'fail'
      fail
    when 'success'
      success
    else
      all
    end
  end

  def self.fail
    where.not(exception_type: ['login', 'logout'] )
  end

  def self.success
    where(exception_type: ['login', 'logout'] )
  end

  def interpolation_attributes
    attributes.symbolize_keys.merge!(user: user.to_s, roles: user&.roles_list)
  end
end
