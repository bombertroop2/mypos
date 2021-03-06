class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  
  # JANGAN LUPA SKIP BEFORE ACTION BARU UNTUK incompatible_browsers_controller
  
  protect_from_forgery with: :exception, prepend: true
  
  before_action :browser_supported, :authenticate_user!#, except: [:show, :index]
  before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :invalidate_simultaneous_user_session, unless: proc {|c| c.controller_name.eql?('sessions') and c.action_name.eql?('create') }
      before_action :get_notifications, if: :user_signed_in?
        around_action :set_time_zone
    
        rescue_from CanCan::AccessDenied do |exception|
          unless request.xhr?
            redirect_to root_url, alert: "You are not authorized to perform this action."
          else
            flash[:alert] = 'You are not authorized to perform this action.'
            render js: "window.location = '#{root_url}'"
          end
        end
  
  
        def after_sign_in_path_for(resource)
          #      sign_in_url = new_user_session_url
          #      if request.referer == sign_in_url
          #        super
          #      else
          #        stored_location_for(resource) || request.referer || root_path
          #      end
          geo_details = Geocoder.search current_user.current_sign_in_ip
          if geo_details.length == 0
            timezone_name = "Jakarta"
          else
            timezone_name = geo_details.first.data["time_zone"] rescue "Jakarta"
          end
          current_user.timezone_name = timezone_name
          current_user.save validate: false
          root_path
        end
    
        def after_sign_out_path_for(resource_or_scope)
          new_user_session_path
        end
  
        protected
        
        def configure_permitted_parameters
          added_attrs = [:username, :email, :password, :password_confirmation, :remember_me]
          devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
          devise_parameter_sanitizer.permit :account_update, keys: added_attrs
        end
  
        private
        
        def browser_supported
          browser = Browser.new(request.user_agent)
          if !browser.chrome? && !browser.firefox?
            unless request.xhr?
              redirect_to incompatible_browsers_index_path
            else
              render js: "window.location = '#{incompatible_browsers_index_url}'"
            end
          end
        end

        def set_time_zone
          begin
            old_time_zone = Time.zone
            begin
              Time.zone = current_user.timezone_name if user_signed_in?
            rescue Exception => e
              Time.zone = "Jakarta"
            end
            yield
          ensure
            Time.zone = old_time_zone
          end
        end
        
        def invalidate_simultaneous_user_session
          sign_out_and_redirect(current_user) if current_user && session[:sign_in_token] != current_user.current_sign_in_token
        end
    
        def get_notifications
          @unnotified_notification_count = Notification.joins(:recipients).where(["recipients.user_id = ? AND notified = ?", current_user.id, false]).count("notifications.id")
          @notifications = Notification.joins(:recipients).select("notifications.*, recipients.notified").where(["recipients.user_id = ? AND read = ?", current_user.id, false]).order("notifications.created_at DESC").limit(4)
        end
  
        def is_request_from_auth_system?
          controller_name.eql?("sessions")
        end
      end
