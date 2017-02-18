include SmartListing::Helper::ControllerExtensions
class AreaManagersController < ApplicationController
  before_action :set_area_manager, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /supervisors
  # GET /supervisors.json
  def index
    like_command =  if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    supervisors_scope = Supervisor.select(:id, :code, :name, :email, :phone, :mobile_phone)
    supervisors_scope = supervisors_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(supervisors_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(supervisors_scope.where(["email #{like_command} ?", "%"+params[:filter]+"%"])).
      or(supervisors_scope.where(["phone #{like_command} ?", "%"+params[:filter]+"%"])).
      or(supervisors_scope.where(["mobile_phone #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @supervisors = smart_listing_create(:supervisors, supervisors_scope, partial: 'area_managers/listing', default_sort: {code: "asc"})
    @supervisors = Supervisor.select :id, :code, :name, :email, :phone, :mobile_phone
  end

  # GET /supervisors/1
  # GET /supervisors/1.json
  def show
  end

  # GET /supervisors/new
  def new
    @supervisor = Supervisor.new
  end

  # GET /supervisors/1/edit
  def edit
  end

  # POST /supervisors
  # POST /supervisors.json
  def create
    @supervisor = Supervisor.new(area_manager_params)
    
    begin
      @supervisor.save
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = if e.message.include? "supervisors.email"
        "That email has already been taken"
      else
        "That code has already been taken"
      end
      render js: "window.location = '#{area_managers_url}'"
    end
  end

  # PATCH/PUT /supervisors/1
  # PATCH/PUT /supervisors/1.json
  def update    
    begin
      @supervisor.update(area_manager_params)
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = if e.message.include? "column email is not unique"
        "That email has already been taken"
      else
        "That code has already been taken"
      end
      render js: "window.location = '#{area_managers_url}'"
    end
  end

  # DELETE /supervisors/1
  # DELETE /supervisors/1.json
  def destroy    
    @supervisor.destroy    
    if @supervisor.errors.present? and @supervisor.errors.messages[:base].present?
      flash[:alert] = @supervisor.errors.messages[:base].to_sentence
      render js: "window.location = '#{area_managers_url}'"
    end    
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_area_manager
    @supervisor = Supervisor.where(id: params[:id]).select(:id, :code, :name, :address, :email, :phone, :mobile_phone).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def area_manager_params
    params.require(:supervisor).permit(:code, :name, :address, :email, :phone, :mobile_phone)
  end
end
