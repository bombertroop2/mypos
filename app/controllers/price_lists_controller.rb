class PriceListsController < ApplicationController
  before_action :set_price_list, only: [:show, :edit, :update, :destroy]
  before_action :convert_price_to_numeric, only: [:create, :update]
  before_action :get_products, only: [:new, :edit]

  # GET /price_lists
  # GET /price_lists.json
  def index
    @price_lists = PriceList.joins(product_detail: [:size, :product, :price_code]).select("price_lists.id, effective_date, price, size, products.code as products_code, common_fields.code as price_codes_code")
  end

  # GET /price_lists/1
  # GET /price_lists/1.json
  def show
  end

  # GET /price_lists/new
  def new
  end

  # GET /price_lists/1/edit
  def edit
    @product = Product.select(:id, :code, :size_group_id).where(id: @price_list.products_id).first
    @sizes = Size.joins(:size_group).select("sizes.id, size").where(size_group_id: @product.size_group_id)
    @price_codes = PriceCode.select :id, :code
    @price_list.product_id = @product.id
    @price_list.effective_date = @price_list.effective_date.strftime("%d/%m/%Y") if @price_list.effective_date
    # dua kode dibawah seharusnya tidak usah, cuma ada bug, rails tidak bisa ambil dua field dibawah hasil innerjoin
    @price_list.size_id = @price_list[:size_id]
    @price_list.price_code_id = @price_list[:price_code_id]
  end

  # POST /price_lists
  # POST /price_lists.json
  def create
    @price_list = PriceList.new(price_list_params)
    @price_list.user_is_adding_new_price = true

    respond_to do |format|
      begin
        if @price_list.save
          format.html { redirect_to price_lists_url, notice: 'Price was successfully created.' }
          format.json { render :show, status: :created, location: @price_list }
        else
          get_products
          @product = Product.select(:id, :code, :size_group_id).where(id: params[:price_list][:product_id]).limit(1).first
          @sizes = Size.joins(:size_group).select("sizes.id, size").where(size_group_id: @product.size_group_id)
          @price_codes = PriceCode.select :id, :code
          format.html { render :new }
          format.json { render json: @price_list.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        get_products
        @product = Product.select(:id, :code, :size_group_id).where(id: params[:price_list][:product_id]).limit(1).first
        @sizes = Size.joins(:size_group).select("sizes.id, size").where(size_group_id: @product.size_group_id)
        @price_codes = PriceCode.select :id, :code
        unless e.message.include?("price_lists.effective_date, price_lists.product_detail_id")
          @price_list.errors.messages[:product_id] = @price_list.errors.messages[:size_id] = @price_list.errors.messages[:price_code_id] = ["has already been taken"]
        else
          @price_list.errors.messages[:product_id] = @price_list.errors.messages[:effective_date] = @price_list.errors.messages[:size_id] = @price_list.errors.messages[:price_code_id] = ["has already been taken"]
        end
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /price_lists/1
  # PATCH/PUT /price_lists/1.json
  def update
    respond_to do |format|
      begin
        if @price_list.update(price_list_params)
          format.html { redirect_to price_lists_url, notice: 'Price was successfully updated.' }
          format.json { render :show, status: :ok, location: @price_list }
        else
          get_products
          @product = Product.select(:id, :code, :size_group_id).where(id: @price_list.products_id).first
          @sizes = Size.joins(:size_group).select("sizes.id, size").where(size_group_id: @product.size_group_id)
          @price_codes = PriceCode.select :id, :code
          format.html { render :edit }
          format.json { render json: @price_list.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        get_products
        @price_list.errors.messages[:effective_date] = ["has already been taken"]
        format.html { render :edit }
      end
    end
  end

  # DELETE /price_lists/1
  # DELETE /price_lists/1.json
  def destroy
    @price_list.user_is_deleting_from_child = true
    unless @price_list.destroy
      alert = @price_list.errors.messages[:base].to_sentence
    else
      notice = "Price was successfully deleted."
    end
    respond_to do |format|
      format.html do 
        if notice.present?
          redirect_to price_lists_url, notice: notice
        else
          redirect_to price_lists_url, alert: alert
        end
      end
      format.json { head :no_content }
    end
  end
  
  def generate_price_form
    @price_list = PriceList.new product_id: params[:id]
    @product = Product.select(:id, :code, :size_group_id).where(id: params[:id]).limit(1).first
    @sizes = Size.joins(:size_group).select("sizes.id, size").where(size_group_id: @product.size_group_id)
    @price_codes = PriceCode.select :id, :code
    respond_to { |format| format.js }
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_price_list
    @price_list = PriceList.joins(product_detail: [:size, :product, :price_code]).select("price_lists.id, price, products.id as products_id, products.code, effective_date, size_id, price_code_id, size, common_fields.code as price_code, product_detail_id").where(id: params[:id]).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def price_list_params
    unless params[:action].eql?("update")
      params.require(:price_list).permit(:effective_date, :price, :product_id, :size_id, :price_code_id)
    else
      params.require(:price_list).permit(:effective_date, :price, :product_id, :size_id, :price_code_id).merge(user_is_updating_price: true)
    end
  end
    
  def get_products
    @products = Product.joins(:brand, :model, :goods_type, :vendor).select("products.id, products.code as products_code, common_fields.name, models_products.name as models_products_name, goods_types_products.name as goods_types_products_name, vendors.name as vendors_name, target")
  end
  
  def convert_price_to_numeric
    params[:price_list][:price] = params[:price_list][:price].gsub("Rp","").gsub(".","").gsub(",",".")
  end
end
