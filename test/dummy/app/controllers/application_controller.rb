class ApplicationController < ActionController::Base
  protect_from_forgery

  def current_messaging_user
    @current_messaging_user ||= User.first
  end
end
