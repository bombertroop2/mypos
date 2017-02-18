include SmartListing::Helper::ControllerExtensions
class RegionsController < ApplicationController
  before_action :set_region, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /regions
  # GET /regions.json
  def index
    like_command =  if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    regions_scope = Region.select(:id, :code, :name, :description)
    regions_scope = regions_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(regions_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(regions_scope.where(["description #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @regions = smart_listing_create(:regions, regions_scope, partial: 'regions/listing', default_sort: {code: "asc"})
  end

  # GET /regions/1
  # GET /regions/1.json
  def show
  end

  # GET /regions/new
  def new
    @region = Region.new
  end

  # GET /regions/1/edit
  def edit
  end

  # POST /regions
  # POST /regions.json
  def create
    @region = Region.new(region_params)

    begin
      @region.save
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{regions_url}'"
    end
  end

  # PATCH/PUT /regions/1
  # PATCH/PUT /regions/1.json
  def update
    begin        
      @region.update(region_params)
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{regions_url}'"
    end
  end

  # DELETE /regions/1
  # DELETE /regions/1.json
  def destroy
    @region.destroy
    
    if @region.errors.present? and @region.errors.messages[:base].present?
      flash[:alert] = @region.errors.messages[:base].to_sentence
      render js: "window.location = '#{regions_url}'"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_region
    @region = Region.where(id: params[:id]).select(:id, :code, :name, :description).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def region_params
    params[:region].permit(:code, :name, :description)
  end
end
