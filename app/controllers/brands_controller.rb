class BrandsController < ApplicationController
  before_action :set_brand, only: [:show, :edit, :update, :destroy]

  # GET /brands
  # GET /brands.json
  def index
    @brands = Brand.all
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

    respond_to do |format|
      begin
        if @brand.save
          format.html { redirect_to @brand, notice: 'Brand was successfully created.' }
          format.json { render :show, status: :created, location: @brand }
        else
          format.html { render :new }
          format.json { render json: @brand.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @brand.errors.messages[:code] = ["has already been taken"]
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /brands/1
  # PATCH/PUT /brands/1.json
  def update
    respond_to do |format|
      begin
        if @brand.update(brand_params)
          format.html { redirect_to @brand, notice: 'Brand was successfully updated.' }
          format.json { render :show, status: :ok, location: @brand }
        else
          format.html { render :edit }
          format.json { render json: @brand.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @brand.errors.messages[:code] = ["has already been taken"]
        format.html { render :edit }
      end
    end
  end

  # DELETE /brands/1
  # DELETE /brands/1.json
  def destroy
    @brand.destroy    
    if @brand.errors.present? and @brand.errors.messages[:base].present?
      message = @brand.errors.messages[:base].to_sentence
    else
      message = 'Brand was successfully destroyed.'
    end
    respond_to do |format|
      format.html { redirect_to brands_url, notice: message }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_brand
    @brand = Brand.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def brand_params
    params[:brand].permit(:code, :name, :description)
  end
end
