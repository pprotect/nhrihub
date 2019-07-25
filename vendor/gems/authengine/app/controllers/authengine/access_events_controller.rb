class Authengine::AccessEventsController < ApplicationController
  def index
    @access_events = AccessEvent.all
    @users = User.all.map(&:first_last_name)
  end
end
