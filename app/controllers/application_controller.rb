class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_action :authenticate_user!, except: [:show, :index]
  before_action :is_user_can_cud?, except: [:show, :index]
  
  def after_sign_in_path_for(resource)
    welcome_index_path
  end
  
  private
  
  def is_admin?
    current_user.has_role? :admin
  end
  
  def is_request_from_auth_system?
    controller_name.eql?("sessions")
  end
  
  def is_user_can_cud?
    if user_signed_in? and !is_admin? and !is_request_from_auth_system?
      flash[:alert] = "Sorry, you can't access this request!"
      redirect_to :back rescue redirect_to root_url
    end
  end
end
