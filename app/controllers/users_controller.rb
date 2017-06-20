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
    @sales_promotion_girls = SalesPromotionGirl.joins(:warehouse).
      select("sales_promotion_girls.id, identifier, sales_promotion_girls.name, warehouses.code AS warehouse_code, role").order("identifier")
  end

  def create
    if params[:user][:sales_promotion_girl_id].blank?
      if current_user.has_role?(params[:user][:role].to_sym)
        render js: "bootbox.alert({message: \"Sorry, you can't create an administrator\",size: 'small'});"
      else
        @user = User.new(user_params)
        if !@user.save
          @invalid = true
          User::MENUS.each do |menu|
            @user.user_menus.build name: menu if @user.user_menus.select{|um| um.name.eql?(menu)}.blank?
          end
        else
          @invalid = false
          @role_name = UsersRole.joins(:role).where(user_id: @user.id).select(:name).first.name
        end
      end
    else
      sales_promotion_girl = SalesPromotionGirl.joins(:warehouse).select("sales_promotion_girls.id, sales_promotion_girls.name, gender, mobile_phone, role").where(id: params[:user][:sales_promotion_girl_id]).first
      if sales_promotion_girl.user.blank?
        @user = User.new(name: sales_promotion_girl.name, gender: sales_promotion_girl.gender,
          mobile_phone: sales_promotion_girl.mobile_phone, role: sales_promotion_girl.role,
          email: params[:user][:email], sales_promotion_girl_id: params[:user][:sales_promotion_girl_id],
          username: params[:user][:username], password: params[:user][:password],
          password_confirmation: params[:user][:password_confirmation], active: params[:user][:active],
          creating_spg_user: true)
        if !@user.save
          if @user.errors.messages[:base].present?
            render js: "bootbox.alert({message: \"#{@user.errors.messages[:base].join("<br/>")}\",size: 'small'});"
          else
            @invalid = true
            User::MENUS.each do |menu|
              @user.user_menus.build name: menu if @user.user_menus.select{|um| um.name.eql?(menu)}.blank?
            end
          end
        else
          @invalid = false
          @role_name = UsersRole.joins(:role).where(user_id: @user.id).select(:name).first.name
        end
      else
        render js: "bootbox.alert({message: \"Sorry, user with name #{sales_promotion_girl.name} already exists\",size: 'small'});"
      end
    end
  end

  def edit
    if @user.has_role?(:superadmin)
      render js: "bootbox.alert({message: \"Sorry, you can't edit super administrator\",size: 'small'});"
    else
      User::MENUS.each do |menu|
        @user.user_menus.build name: menu if @user.user_menus.select{|um| um.name.eql?(menu)}.blank?
      end
      @user.role = @user.roles.first.name if User::SPG_ROLES.select{|a, b| b.eql?(@user.roles.first.name)}.present?
    end
  end

  def update
    if @user.has_role?(:superadmin)
      render js: "bootbox.alert({message: \"Sorry, you can't edit super administrator\",size: 'small'});"
    else
      @user.updating_spg_user = params[:user][:sales_promotion_girl_id].present?
      unless @user.update(user_params)
        if @user.errors.messages[:base].present?
          render js: "bootbox.alert({message: \"#{@user.errors.messages[:base].join("<br/>")}\",size: 'small'});"
        else
          @invalid = true
          User::MENUS.each do |menu|
            @user.user_menus.build name: menu if @user.user_menus.select{|um| um.name.eql?(menu)}.blank?
          end
          @user.role = @user.roles.first.name if User::SPG_ROLES.select{|a, b| b.eql?(@user.roles.first.name)}.present?
        end
      else
        @invalid = false
        @role_name = UsersRole.joins(:role).where(user_id: @user.id).select(:name).first.name
      end
    end
  end

  def destroy
    if @user.has_role?(:superadmin)
      render js: "bootbox.alert({message: \"Sorry, you can't delete super administrator\",size: 'small'});"
    else
      unless @user.destroy
        render js: "bootbox.alert({message: \"Sorry, you can't delete #{@user.name}\",size: 'small'});"
      end
    end
  end
  
  def generate_spg_user_form
    sales_promotion_girl = SalesPromotionGirl.joins(:warehouse).select("sales_promotion_girls.id, sales_promotion_girls.name, gender, mobile_phone, role").where(id: params[:spg_id]).first
    if sales_promotion_girl.user.blank?
      @user = User.new name: sales_promotion_girl.name, gender: sales_promotion_girl.gender,
        mobile_phone: sales_promotion_girl.mobile_phone, role: sales_promotion_girl.role,
        sales_promotion_girl_id: sales_promotion_girl.id
      User::MENUS.each do |menu|
        @user.user_menus.build name: menu
      end
    else
      render js: "bootbox.alert({message: \"Sorry, user with name #{sales_promotion_girl.name} already exists\",size: 'small'});"
    end    
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.joins(users_roles: :role).where(id: params[:id]).
      select(:id, :email, :name, :address, :phone, :mobile_phone, :gender, :username, :active, :sales_promotion_girl_id).
      select("roles.name AS role_name").first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params[:user].permit(:sales_promotion_girl_id, :name, :gender, :mobile_phone, :role, :email, :password, :password_confirmation, :username, :active,
      user_menus_attributes: [:id, :name, :ability])
  end
end
