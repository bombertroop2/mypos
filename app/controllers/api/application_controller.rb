class Api::ApplicationController < ActionController::Base  
  protect_from_forgery with: :null_session

  respond_to :json
  
  before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :authenticate_user
    
    rescue_from CanCan::AccessDenied do |exception|
      render json: { status: false, message: "You are not authorized to perform this action." }, status: :unauthorized
    end
    
    private

    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_up) << :username
    end

    def authenticate_user
      if request.headers['Authorization'].present?
        authenticate_or_request_with_http_token do |token|
          begin
            jwt_payload = JWT.decode(token, Rails.application.secrets.secret_key_base).first

            @current_user_id = jwt_payload['id']
          rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError
            head :unauthorized
          end
        end
      end
    end
    
    def authenticate_user!(options = {})
      unless signed_in?
        head :unauthorized
      else
        if current_user.has_non_spg_role? || (current_user.sales_promotion_girl_id.present? && current_user.sales_promotion_girl.warehouse.warehouse_type.include?("ctr"))
        else
          head :unauthorized
        end
      end
    end
  

    def current_user
      @current_user ||= super || User.find(@current_user_id)
    end

    def signed_in?
      @current_user_id.present?
    end
  end
