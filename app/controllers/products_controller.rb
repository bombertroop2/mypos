class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

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
    sg = @product.sizes.first.size_group rescue nil
    @sizes = sg ? sg.sizes.order(:size) : []
    @price_codes = PriceCode.order :code
    @colors = Color.order :code
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @product }
      else
        sg = SizeGroup.find(params[:size_groups]) rescue nil
        @sizes = sg ? sg.sizes.order(:size) : []
        @price_codes = PriceCode.order :code
        @colors = Color.order :code
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @product }
      else
        sg = SizeGroup.find(params[:size_groups]) rescue nil
        @sizes = sg ? sg.sizes.order(:size) : []
        @price_codes = PriceCode.order :code
        @colors = Color.order :code
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def populate_detail_form
    @product = Product.new
    sg = SizeGroup.find(params[:id]) rescue nil
    @sizes = sg.sizes.order(:size) if sg
    @price_codes = PriceCode.order :code
    @colors = Color.order :code
    #    @price_codes.each do |price_code|
    #      @sizes.each do |size|
    #        @colors.each do |color|
    #          @product.product_details.build(price_code_id: price_code.id, size_id: size.id, color_id: color.id)  
    #        end
    #      end
    #    end
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
      :goods_type_id, :image, :effective_date, :image_cache, :remove_image, :cost,
      product_details_attributes: [:id, :size_id, :color_id, :price_code_id, :price])
  end
end
