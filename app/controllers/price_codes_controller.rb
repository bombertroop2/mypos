class PriceCodesController < ApplicationController
  before_action :set_price_code, only: [:show, :edit, :update, :destroy]

  # GET /price_codes
  # GET /price_codes.json
  def index
    @price_codes = PriceCode.all
  end

  # GET /price_codes/1
  # GET /price_codes/1.json
  def show
  end

  # GET /price_codes/new
  def new
    @price_code = PriceCode.new
  end

  # GET /price_codes/1/edit
  def edit
  end

  # POST /price_codes
  # POST /price_codes.json
  def create
    @price_code = PriceCode.new(price_code_params)

    respond_to do |format|
      if @price_code.save
        format.html { redirect_to @price_code, notice: 'Price code was successfully created.' }
        format.json { render :show, status: :created, location: @price_code }
      else
        format.html { render :new }
        format.json { render json: @price_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /price_codes/1
  # PATCH/PUT /price_codes/1.json
  def update
    respond_to do |format|
      if @price_code.update(price_code_params)
        format.html { redirect_to @price_code, notice: 'Price code was successfully updated.' }
        format.json { render :show, status: :ok, location: @price_code }
      else
        format.html { render :edit }
        format.json { render json: @price_code.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /price_codes/1
  # DELETE /price_codes/1.json
  def destroy
    @price_code.destroy
    if @price_code.errors.present? and @price_code.errors.messages[:base].present?
      message = @price_code.errors.messages[:base].to_sentence
    else
      message = 'Price code was successfully destroyed.'
    end
    respond_to do |format|
      format.html { redirect_to price_codes_url, notice: message }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_price_code
      @price_code = PriceCode.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def price_code_params
      params.require(:price_code).permit(:code, :name, :description)
    end
end
