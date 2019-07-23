class Authengine::AccessEventsController < ApplicationController
  def index
    @access_events = AccessEvent.all
  end
end
