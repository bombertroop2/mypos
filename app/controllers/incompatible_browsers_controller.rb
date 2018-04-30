class IncompatibleBrowsersController < ApplicationController
  skip_before_action :authenticate_user!, :invalidate_simultaneous_user_session, :set_time_zone, :browser_supported
  def index
  end
end
