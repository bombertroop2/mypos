class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true
  
  before_action :authenticate_user!, except: [:show, :index]
  before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :get_notifications, if: :user_signed_in?
    
    rescue_from CanCan::AccessDenied do |exception|
      #      flash[:alert] = exception.message
      flash[:alert] = "You are not authorized to perform this action."
      unless request.xhr?
        redirect_to root_path
      else
        render js: "window.location = '#{root_url}'"
      end
    end
  
  
    def after_sign_in_path_for(resource)
      sign_in_url = new_user_session_url
      if request.referer == sign_in_url
        super
      else
        stored_location_for(resource) || request.referer || root_path
      end
    end
  
    protected

    def configure_permitted_parameters
      added_attrs = [:username, :email, :password, :password_confirmation, :remember_me]
      devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
      devise_parameter_sanitizer.permit :account_update, keys: added_attrs
    end
  
    private
    
    def get_notifications
      @notifications = Notification.all.reverse
    end
  
    def is_request_from_auth_system?
      controller_name.eql?("sessions")
    end
  end
