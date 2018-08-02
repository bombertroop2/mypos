include SmartListing::Helper::ControllerExtensions
class UsersController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  
  def show
  end

  def index
    like_command = "ILIKE"
    users_scope = User.select(:id, :name, :gender).select("roles.name AS role_name").joins(users_roles: :role)
    users_scope = users_scope.where(["users.name #{like_command} ?", "%"+params[:filter_string]+"%"]) if params[:filter_string]
    users_scope = users_scope.where(["gender = ?", params[:filter_gender]]) if params[:filter_gender].present?
    users_scope = users_scope.where(["roles.name = ?", params[:filter_role]]) if params[:filter_role].present?
    @users = smart_listing_create(:users, users_scope, partial: 'users/listing', default_sort: {:"users.name" => "asc"})
  end

  def new
    @user = User.new
    AvailableMenu.select(:name).where(active: true).each do |menu|
      @user.user_menus.build name: menu.name
    end
    @sales_promotion_girls = SalesPromotionGirl.joins(:warehouse).
      select("sales_promotion_girls.id, identifier, sales_promotion_girls.name, warehouses.code AS warehouse_code, role").order("identifier")
    @area_managers = Supervisor.select(:id, :code, :name).order(:code)
  end

  def create
    if params[:user][:sales_promotion_girl_id].blank? && !params[:user][:supervisor_id]
      if current_user.has_role?(params[:user][:role].to_sym)
        render js: "bootbox.alert({message: \"Sorry, you can't create an administrator\",size: 'small'});"
      else
        @user = User.new(user_params)
        if !@user.save
          @invalid = true
          AvailableMenu.select(:name).where(active: true).each do |menu|
            @user.user_menus.build name: menu.name if @user.user_menus.select{|um| um.name.eql?(menu.name)}.blank?
          end
        else
          @invalid = false
          @role_name = UsersRole.joins(:role).where(user_id: @user.id).select(:name).first.name
        end
      end
    elsif params[:user][:sales_promotion_girl_id].present?
      sales_promotion_girl = SalesPromotionGirl.joins(:warehouse).select("sales_promotion_girls.id, sales_promotion_girls.name, gender, mobile_phone, role").where(id: params[:user][:sales_promotion_girl_id]).first
      if sales_promotion_girl.user.blank?
        params[:user].merge! name: sales_promotion_girl.name, gender: sales_promotion_girl.gender, mobile_phone: sales_promotion_girl.mobile_phone, role: sales_promotion_girl.role, creating_spg_user: true
        @user = User.new(user_params)
        if !@user.save
          if @user.errors.messages[:base].present?
            render js: "bootbox.alert({message: \"#{@user.errors.messages[:base].join("<br/>")}\",size: 'small'});"
          else
            @invalid = true
            AvailableMenu.select(:name).where(active: true).each do |menu|
              @user.user_menus.build name: menu.name if @user.user_menus.select{|um| um.name.eql?(menu.name)}.blank?
            end
          end
        else
          @invalid = false
          @role_name = UsersRole.joins(:role).where(user_id: @user.id).select(:name).first.name
        end
      else
        render js: "bootbox.alert({message: \"Sorry, user with name #{sales_promotion_girl.name} already exists\",size: 'small'});"
      end
    else
      area_manager = Supervisor.select(:id, :name, :mobile_phone).where(id: params[:user][:supervisor_id]).first
      if area_manager.blank? || area_manager.user.blank?
        params[:user].merge! name: (area_manager.present? ? area_manager.name : nil), mobile_phone: (area_manager.present? ? area_manager.mobile_phone : nil), role: "area_manager", attr_creating_am_user: true
        @user = User.new(user_params)
        if !@user.save
          if @user.errors.messages[:base].present?
            render js: "bootbox.alert({message: \"#{@user.errors.messages[:base].join("<br/>")}\",size: 'small'});"
          else
            @invalid = true
            @area_managers = Supervisor.select(:id, :code, :name).order(:code)
            AvailableMenu.select(:name).where(active: true).each do |menu|
              @user.user_menus.build name: menu.name if @user.user_menus.select{|um| um.name.eql?(menu.name)}.blank?
            end
          end
        else
          @invalid = false
          @role_name = UsersRole.joins(:role).where(user_id: @user.id).select(:name).first.name
        end
      else
        render js: "bootbox.alert({message: \"Sorry, user with name #{area_manager.name} already exists\",size: 'small'});"
      end
    end
  end

  def edit
    if @user.has_role?(:superadmin)
      render js: "bootbox.alert({message: \"Sorry, you can't edit super administrator\",size: 'small'});"
    elsif current_user.has_role?(:administrator) && @user.has_role?(:administrator)
      render js: "bootbox.alert({message: \"Sorry, you can't edit administrator\",size: 'small'});"
    else
      @area_managers = Supervisor.select(:id, :code, :name).order(:code)
      AvailableMenu.select(:name).where(active: true).each do |menu|
        @user.user_menus.build name: menu.name if @user.user_menus.select{|um| um.name.eql?(menu.name)}.blank?
      end
      @user.role = @user.roles.first.name if User::SPG_ROLES.select{|a, b| b.eql?(@user.roles.first.name)}.present?
    end
  end

  def update
    if @user.has_role?(:superadmin)
      render js: "bootbox.alert({message: \"Sorry, you can't edit super administrator\",size: 'small'});"
    elsif current_user.has_role?(:administrator) && @user.has_role?(:administrator)
      render js: "bootbox.alert({message: \"Sorry, you can't edit administrator\",size: 'small'});"
    elsif (params[:user][:role].present? && current_user.has_role?(params[:user][:role].to_sym)) || (current_user.has_role?(:administrator) && params[:user][:role].eql?("superadmin"))
      render js: "bootbox.alert({message: \"Sorry, you can't change user's role from #{@user.roles.first.name} to #{params[:user][:role]}\",size: 'small'});"
    else
      if params[:user][:sales_promotion_girl_id].present?
        @user.updating_spg_user = true
      elsif params[:user][:supervisor_id].present?
        @user.updating_am_user = true
      end
      unless @user.update(user_params_edit)
        if @user.errors.messages[:base].present?
          render js: "bootbox.alert({message: \"#{@user.errors.messages[:base].join("<br/>")}\",size: 'small'});"
        else
          @invalid = true
          AvailableMenu.select(:name).where(active: true).each do |menu|
            @user.user_menus.build name: menu.name if @user.user_menus.select{|um| um.name.eql?(menu.name)}.blank?
          end
          unless @user.roles.first.name.eql?("area_manager")
            @user.role = @user.roles.first.name if User::SPG_ROLES.select{|a, b| b.eql?(@user.roles.first.name)}.present?
          end
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
      AvailableMenu.select(:name).where(active: true).each do |menu|
        @user.user_menus.build name: menu.name
      end
    else
      render js: "bootbox.alert({message: \"Sorry, user with name #{sales_promotion_girl.name} already exists\",size: 'small'});"
    end    
  end
  
  def get_area_manager_info
    @area_manager = Supervisor.select(:email, :mobile_phone).find(params[:supervisor_id])
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.joins(users_roles: :role).where(id: params[:id]).
      select(:id, :email, :name, :mobile_phone, :gender, :username, :active, :sales_promotion_girl_id, :supervisor_id).
      select("roles.name AS role_name").first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    if params[:user][:supervisor_id]
      params[:user].permit(:supervisor_id, :name, :gender, :mobile_phone, :role, :email, :password, :password_confirmation, :username, :active, :attr_creating_am_user,
        user_menus_attributes: [:id, :name, :ability])
    else
      params[:user].permit(:sales_promotion_girl_id, :name, :gender, :mobile_phone, :role, :email, :password, :password_confirmation, :username, :active, :creating_spg_user,
        user_menus_attributes: [:id, :name, :ability])
    end
  end

  def user_params_edit
    if @user.updating_am_user
      params[:user].permit(:gender, :email, :password, :password_confirmation, :username, :active,
        user_menus_attributes: [:id, :name, :ability])
    else
      params[:user].permit(:sales_promotion_girl_id, :name, :gender, :mobile_phone, :role, :email, :password, :password_confirmation, :username, :active, :creating_spg_user,
        user_menus_attributes: [:id, :name, :ability])
    end
  end
end
