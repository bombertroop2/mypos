include SmartListing::Helper::ControllerExtensions
class BrandsController < ApplicationController  
  load_and_authorize_resource
  before_action :set_brand, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper
  # GET /brands
  # GET /brands.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    brands_scope = Brand.select(:id, :code, :name, :description)
    brands_scope = brands_scope.where(["code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(brands_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(brands_scope.where(["description #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @brands = smart_listing_create(:brands, brands_scope, partial: 'brands/listing', default_sort: {code: "asc"})
  end

  # GET /brands/1
  # GET /brands/1.json
  def show
  end

  # GET /brands/new
  def new
    @brand = Brand.new
  end

  # GET /brands/1/edit
  def edit
  end

  # POST /brands
  # POST /brands.json
  def create
    @brand = Brand.new(brand_params)

    begin
      @brand.save
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{brands_url}'"
    end
  end

  # PATCH/PUT /brands/1
  # PATCH/PUT /brands/1.json
  def update
    begin
      @brand.update(brand_params)
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{brands_url}'"
    end
  end

  # DELETE /brands/1
  # DELETE /brands/1.json
  def destroy
    @brand.destroy    
    if @brand.errors.present? and @brand.errors.messages[:base].present?
      flash[:alert] = @brand.errors.messages[:base].to_sentence
      render js: "window.location = '#{brands_url}'"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_brand
    @brand = Brand.where(id: params[:id]).select(:id, :code, :name, :description).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def brand_params
    params[:brand].permit(:code, :name, :description)
  end
end
