class PrintBarcodeTempsController < ApplicationController
  before_action :set_print_barcode_temp, only: [:show, :edit, :update, :destroy]

  # GET /print_barcode_temps
  # GET /print_barcode_temps.json
  def index
    @print_barcode_temps = PrintBarcodeTemp.all
  end

  # GET /print_barcode_temps/1
  # GET /print_barcode_temps/1.json
  def show
  end

  # GET /print_barcode_temps/new
  def new
    @print_barcode_temp = PrintBarcodeTemp.new
  end

  # GET /print_barcode_temps/1/edit
  def edit
  end

  # POST /print_barcode_temps
  # POST /print_barcode_temps.json
  def create
    unless validate_quantities
      render js: "bootbox.alert({message: \"Quantity must be greater than or equal to 1\",size: 'small'});"
    else
      ActiveRecord::Base.transaction do
        PrintBarcodeTemp.delete_all(internet_client_address: request.remote_ip)
        params[:product].each do |k, v|
          params[:product][k].each do |key, val|
            params[:product][k][key].each do |x, y|
              qty = params[:product][k][key][x][:quantity].to_i
              qty.times do                
                splitted_key = key.split("-")
                splitted_key.shift
                color_name = splitted_key.join("-")
                @print_barcode_temp = PrintBarcodeTemp.new(product_code: k, brand_name: params[:product][k][key][x][:brand_name], product_description: params[:product][k][key][x][:product_description], barcode: params[:product][k][key][x][:product_barcode], size: x, color_name: color_name, price: params[:product][k][key][x][:price], internet_client_address: request.remote_ip)
                @print_barcode_temp.save
              end
            end
          end
        end
      end
    end
  end

  # PATCH/PUT /print_barcode_temps/1
  # PATCH/PUT /print_barcode_temps/1.json
  def update
    respond_to do |format|
      if @print_barcode_temp.update(print_barcode_temp_params)
        format.html { redirect_to @print_barcode_temp, notice: 'Print barcode temp was successfully updated.' }
        format.json { render :show, status: :ok, location: @print_barcode_temp }
      else
        format.html { render :edit }
        format.json { render json: @print_barcode_temp.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /print_barcode_temps/1
  # DELETE /print_barcode_temps/1.json
  def destroy
    @print_barcode_temp.destroy
    respond_to do |format|
      format.html { redirect_to print_barcode_temps_url, notice: 'Print barcode temp was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def search_product
    products = Product.joins(:brand).where(["products.code ILIKE ?", params[:term]+"%"]).order(:code).pluck(:code)
    respond_to do |format|
      format.json  { render :json => products.to_json } # don't do msg.to_json
    end
  end
  
  def add_product
    @product = Product.
      select(:id, :code, :description, "common_fields.name AS brand_name").
      joins(:brand).
      includes([product_details: :size], product_colors: [:color, product_barcodes: :size]).
      where(["products.code = ?", params[:product_code]]).first
    if @product.blank?
      render js: "bootbox.alert({message: \"Product #{params[:product_code]} doesn't exist\",size: 'small'});"
    else
      @available_product_details = @product.product_details.select{|pd| pd.price_code_id == params[:price_code_id].to_i}
      @price_lists = PriceList.select(:price, :product_detail_id, :effective_date).where(product_detail_id: @available_product_details.map(&:id)).where(["price_lists.effective_date <= ?", params[:effective_date].to_date]).order("effective_date DESC")
      @available_product_details.each do |available_product_detail|
        if @price_lists.select{|pl| pl.product_detail_id == available_product_detail.id}.blank?          
          render js: "bootbox.alert({message: \"Sorry, price of product (code: #{params[:product_code]}, size: #{available_product_detail.size.size}) is not available\",size: 'small'});" and return
        end
      end
    end
  end

  private
  
  def validate_quantities
    valid = true
    all_blank = true
    params[:product].each do |k, v|
      params[:product][k].each do |key, val|
        params[:product][k][key].each do |x, y|
          qty = params[:product][k][key][x][:quantity]
          if qty.present? && qty.to_i == 0
            valid = false
            all_blank = false
          elsif qty.present?
            all_blank = false
          end
        end
      end
    end
    if all_blank
      valid = false
    end
    valid
  end
  
  # Use callbacks to share common setup or constraints between actions.
  def set_print_barcode_temp
    @print_barcode_temp = PrintBarcodeTemp.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def print_barcode_temp_params
    params.require(:print_barcode_temp).permit(:product_code, :brand_name, :product_description, :barcode, :size, :color_name, :price, :internet_client_address)
  end
end
