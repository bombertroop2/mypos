include SmartListing::Helper::ControllerExtensions
class UsersController < ApplicationController
  load_and_authorize_resource
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper
  
  def show
  end

  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    users_scope = User.select(:id, :name, :gender).select("roles.name AS role_name").joins(users_roles: :role)
    users_scope = users_scope.where(["users.name #{like_command} ?", "%"+params[:filter_string]+"%"]) if params[:filter_string]
    users_scope = users_scope.where(["gender = ?", params[:filter_gender]]) if params[:filter_gender].present?
    users_scope = users_scope.where(["roles.name = ?", params[:filter_role]]) if params[:filter_role].present?
    @users = smart_listing_create(:users, users_scope, partial: 'users/listing', default_sort: {:"users.name" => "asc"})
  end

  def new
    @user = User.new
    User::MENUS.each do |menu|
      @user.user_menus.build name: menu
    end
  end

  def create
    @user = User.new(user_params)
    unless @user.save
      @invalid = true
      User::MENUS.each do |menu|
        @user.user_menus.build name: menu if @user.user_menus.select{|um| um.name.eql?(menu)}.blank?
      end
    else
      @invalid = false
      @role_name = UsersRole.joins(:role).where(user_id: @user.id).select(:name).first.name.titleize
    end
  end

  def edit
    User::MENUS.each do |menu|
      @user.user_menus.build name: menu if @user.user_menus.select{|um| um.name.eql?(menu)}.blank?
    end
  end

  def update
    unless @user.update(user_params)
      @invalid = true
      User::MENUS.each do |menu|
        @user.user_menus.build name: menu if @user.user_menus.select{|um| um.name.eql?(menu)}.blank?
      end
    else
      @invalid = false
      @role_name = UsersRole.joins(:role).where(user_id: @user.id).select(:name).first.name.titleize
    end
  end

  def destroy
    @user.destroy
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.joins(users_roles: :role).where(id: params[:id]).
      select(:id, :email, :name, :address, :phone, :mobile_phone, :gender, :username, :active).
      select("roles.name AS role_name").first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params[:user].permit(:name, :gender, :mobile_phone, :role, :email, :password, :password_confirmation, :username, :active,
      user_menus_attributes: [:id, :name, :ability])
  end
end
