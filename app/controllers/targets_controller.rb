include SmartListing::Helper::ControllerExtensions
class TargetsController < ApplicationController
  helper SmartListing::Helper
  before_action :set_target, only: [:show, :edit, :update, :destroy]

  # GET /targets
  # GET /targets.json
  def index
    @targets = Target.all
    like_command = "ILIKE"
    targets_scope = Target.joins(:warehouse).select("targets.*,warehouses.code AS warehouse_code")
    targets_scope = targets_scope.where(["CAST(targets.month AS varchar) #{like_command} ?", "%"+params[:filter]+"%"]).
      or(targets_scope.where(["CAST(targets.year AS varchar) #{like_command} ?", "%"+params[:filter]+"%"])).
      or(targets_scope.where(["CAST(targets.target_value AS varchar) #{like_command} ?", "%"+params[:filter]+"%"])).
      or(targets_scope.where(["warehouses.code #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @targets = smart_listing_create(:targets, targets_scope, partial: 'targets/listing', default_sort: {year:  "asc"})
  end

  # GET /targets/1
  # GET /targets/1.json
  def show
  end

  # GET /targets/new
  def new
    @target = Target.new
  end

  # GET /targets/1/edit
  def edit
  end

  # POST /targets
  # POST /targets.json
  def create
    params[:target][:target_value] = params[:target][:target_value].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:target][:target_value].present?
    @target = Target.new(target_params)
    begin
      @created = @target.save
    rescue ActiveRecord::RecordNotUnique => e
      @created = false
      @target.errors.messages[:month] = ["has already been taken"]
    end
  end

  # PATCH/PUT /targets/1
  # PATCH/PUT /targets/1.json
  def update
    params[:target][:target_value] = params[:target][:target_value].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:target][:target_value].present?
    begin
      @updated = @target.update(target_params)
    rescue ActiveRecord::RecordNotUnique => e
      @updated = false
      @target.errors.messages[:month] = ["has already been taken"]
    end
  end

  # DELETE /targets/1
  # DELETE /targets/1.json
  def destroy
    @target.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_target
      @target = Target.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def target_params
      params.require(:target).permit(:warehouse_id, :month, :year, :target_value)
    end
end
