class Api::SessionsController < Devise::SessionsController
  #  authorize_resource
  skip_before_action :verify_authenticity_token

  def create
    user = User.where(["(lower(username) = :value OR lower(email) = :value) AND active = :active_value", {value: params[:email].strip.downcase, active_value: true}]).first

    if user && user.valid_password?(params[:password])
      @current_user = user
    else
      render json: { status: false, message: "Invalid login or password" }, status: :unprocessable_entity
    end
  end
end
