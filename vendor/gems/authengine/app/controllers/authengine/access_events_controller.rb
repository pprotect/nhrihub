class Authengine::AccessEventsController < ApplicationController
  def index
    @access_events = AccessEvent.all
    @users = User.all
  end
end
