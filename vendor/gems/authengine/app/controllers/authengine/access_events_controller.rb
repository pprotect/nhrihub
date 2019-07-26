class Authengine::AccessEventsController < ApplicationController
  def index
    if request.xhr?
      access_events = AccessEvent.filtered_by(params.slice(:user, :period, :outcome)).includes(:user => :roles)
      render access_events
    else
      @users = User.all # populates filter select box on first load
    end
  end
end
