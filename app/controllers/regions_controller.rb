class RegionsController < ApplicationController
  before_action :set_region, only: [:show, :edit, :update, :destroy]

  # GET /regions
  # GET /regions.json
  def index
    @regions = Region.all
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

    respond_to do |format|
      begin
        if @region.save
          format.html { redirect_to @region, notice: 'Region was successfully created.' }
          format.json { render :show, status: :created, location: @region }
        else
          format.html { render :new }
          format.json { render json: @region.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @region.errors.messages[:code] = ["has already been taken"]
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /regions/1
  # PATCH/PUT /regions/1.json
  def update
    respond_to do |format|
      begin
        if @region.update(region_params)
          format.html { redirect_to @region, notice: 'Region was successfully updated.' }
          format.json { render :show, status: :ok, location: @region }
        else
          format.html { render :edit }
          format.json { render json: @region.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @region.errors.messages[:code] = ["has already been taken"]
        format.html { render :edit }
      end
    end
  end

  # DELETE /regions/1
  # DELETE /regions/1.json
  def destroy
    @region.destroy
    if @region.errors.present? and @region.errors.messages[:base].present?
      message = @region.errors.messages[:base].to_sentence
    else
      message = 'Region was successfully destroyed.'
    end
    respond_to do |format|
      format.html { redirect_to regions_url, notice: message }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_region
    @region = Region.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def region_params
    params[:region].permit(:code, :name, :description)
  end
end
