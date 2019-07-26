class Authengine::AccessEventsController < ApplicationController
  def index
    @access_events = AccessEvent.filtered_by(params.slice(:user, :period, :outcome)).includes(:user => :roles)
    if request.xhr?
      render @access_events
    else
      @users = User.all
    end
  end
end
