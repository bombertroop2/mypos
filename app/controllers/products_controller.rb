class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_filter :convert_cost_price_to_numeric, only: [:create, :update]

  # GET /products
  # GET /products.json
  def index
    @products = Product.all
  end

  # GET /products/1
  # GET /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
    @product.effective_date = @product.effective_date.strftime("%d/%m/%Y")
    @sizes = @product.size_group ? @product.size_group.sizes.order(:size) : []
    @price_codes = PriceCode.order :code
    @price_codes.each do |price_code|
      @sizes.each do |size|
        @product.product_details.build(price_code_id: price_code.id, size_id: size.id) if @product.product_details.select{|pd| pd.price_code_id.eql?(price_code.id) and pd.size_id.eql?(size.id)}.blank?
      end
    end
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)
    respond_to do |format|
      begin
        if @product.save
          format.html { redirect_to @product, notice: 'Product was successfully created.' }
          format.json { render :show, status: :created, location: @product }
        else
          size_group = SizeGroup.find(@product.size_group_id) rescue nil
          @sizes = size_group ? size_group.sizes.order(:size) : []
          @price_codes = PriceCode.order :code
          @price_codes.each do |price_code|
            @sizes.each do |size|
              @product.product_details.build(price_code_id: price_code.id, size_id: size.id) if @product.product_details.select{|pd| pd.price_code_id.eql?(price_code.id) and pd.size_id.eql?(size.id)}.blank?
            end
          end
          if @product.errors[:base].present?
            flash.now[:alert] = @product.errors[:base].to_sentence
          end
          format.html { render :new }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        size_group = SizeGroup.find(@product.size_group_id) rescue nil
        @sizes = size_group ? size_group.sizes.order(:size) : []
        @price_codes = PriceCode.order :code
        @price_codes.each do |price_code|
          @sizes.each do |size|
            @product.product_details.build(price_code_id: price_code.id, size_id: size.id) if @product.product_details.select{|pd| pd.price_code_id.eql?(price_code.id) and pd.size_id.eql?(size.id)}.blank?
          end
        end
        @product.errors.messages[:code] = ["has already been taken"]
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      begin
        if @product.update(product_params)
          format.html { redirect_to @product, notice: 'Product was successfully updated.' }
          format.json { render :show, status: :ok, location: @product }
        else
          @sizes = @product.size_group ? @product.size_group.sizes.order(:size) : []
          @price_codes = PriceCode.order :code
          @price_codes.each do |price_code|
            @sizes.each do |size|
              @product.product_details.build(price_code_id: price_code.id, size_id: size.id) if @product.product_details.select{|pd| pd.price_code_id.eql?(price_code.id) and pd.size_id.eql?(size.id)}.blank?
            end
          end
          format.html { render :edit }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @sizes = @product.size_group ? @product.size_group.sizes.order(:size) : []
        @price_codes = PriceCode.order :code
        @price_codes.each do |price_code|
          @sizes.each do |size|
            @product.product_details.build(price_code_id: price_code.id, size_id: size.id) if @product.product_details.select{|pd| pd.price_code_id.eql?(price_code.id) and pd.size_id.eql?(size.id)}.blank?
          end
        end
        @product.errors.messages[:code] = ["has already been taken"]
        format.html { render :edit }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    if @product.errors.present? and @product.errors.messages[:base].present?
      error_message = @product.errors.messages[:base].to_sentence
      error_message.slice! "products "
      alert = error_message
    else
      notice = 'Product was successfully deleted.'
    end
    respond_to do |format|
      format.html do 
        if notice.present?
          redirect_to products_url, notice: notice
        else
          redirect_to products_url, alert: alert
        end
      end
      format.json { head :no_content }
    end
  end
  
  def populate_detail_form
    @product = Product.new
    sg = SizeGroup.find(params[:id]) rescue nil
    @sizes = sg.sizes.order(:size) if sg
    @price_codes = PriceCode.order :code
    @price_codes.each do |price_code|
      @sizes.each do |size|
        @product.product_details.build(price_code_id: price_code.id, size_id: size.id)
      end
    end
    respond_to { |format| format.js }
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:code, :description, :brand_id, :sex, :vendor_id, :target, :model_id,
      :goods_type_id, :image, :effective_date, :image_cache, :remove_image, :cost, :size_group_id,
      product_details_attributes: [:id, :size_id, :price_code_id, :price]
    )
  end
  
  def convert_cost_price_to_numeric
    params[:product][:cost] = params[:product][:cost].gsub("Rp","").gsub(".","").gsub(",",".")
    params[:product][:product_details_attributes].each do |key, value|
      params[:product][:product_details_attributes][key][:price] = params[:product][:product_details_attributes][key][:price].gsub("Rp","").gsub(".","").gsub(",",".")
    end if params[:product][:product_details_attributes].present?
  end
end
