include SmartListing::Helper::ControllerExtensions
class ProductsController < ApplicationController
  helper SmartListing::Helper
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :convert_cost_price_to_numeric, only: [:create, :update]

  # GET /products
  # GET /products.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    products_scope = Product.joins(:brand, :vendor, :model, :goods_type).
      select("products.id, products.code, common_fields.name as brand_name, vendors.name as vendor_name, models_products.name as models_name, goods_types_products.name as goods_type_name")
    products_scope = products_scope.where(["products.code #{like_command} ?", "%"+params[:filter]+"%"]).
      or(products_scope.where(["common_fields.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(products_scope.where(["vendors.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(products_scope.where(["models_products.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(products_scope.where(["goods_types_products.name #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @products = smart_listing_create(:products, products_scope, partial: 'products/listing', default_sort: {:"products.code" => "asc"})
  end

  # GET /products/1
  # GET /products/1.json
  def show
    @product_colors = @product.color_codes.pluck(:code).to_sentence
  end

  # GET /products/new
  def new
    @product = Product.new
    @product.cost_lists.build
    @colors = Color.select(:id, :code, :name).order(:code)
    @colors.each do |color|
      @product.product_colors.build color_id: color.id, code: color.code, name: color.name
    end
  end

  # GET /products/1/edit
  def edit
    @product.effective_date = @product.active_effective_date.strftime("%d/%m/%Y")
    @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size) : []
    @price_codes = PriceCode.select(:id, :code).order :code
    @colors = Color.select(:id, :code, :name).order(:code)
    @colors.each do |color|
      product_color = @product.product_colors.select{|product_color| product_color.color_id.eql?(color.id)}.first
      if product_color
        product_color.selected_color_id = color.id
        product_color.code = color.code
        product_color.name = color.name
      else
        @product.product_colors.build color_id: color.id, code: color.code, name: color.name
      end      
    end
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)
    begin
      unless @product.save
        size_group = SizeGroup.where(id: @product.size_group_id).select(:id).first
        @sizes = size_group ? size_group.sizes.select(:id, :size).order(:size) : []
        @price_codes = PriceCode.select(:id, :code).order :code
        #        @price_codes.each do |price_code|
        #          @sizes.each do |size|
        #            product_detail = @product.product_details.select{|pd| pd.price_code_id.eql?(price_code.id) and pd.size_id.eql?(size.id)}.first
        #            product_detail = @product.product_details.build(price_code_id: price_code.id, size_id: size.id)# if product_detail.blank?
        #            price_list = product_detail.price_lists.select{|pl| pl.price.present?}
        #            product_detail.price_lists.build #if price_list.blank?
        #          end
        #        end
        @colors = Color.select(:id, :code, :name).order(:code)
        @colors.each do |color|
          @product.product_colors.build color_id: color.id, code: color.code, name: color.name unless @product.product_colors.select{|product_color| product_color.color_id.eql?(color.id)}.present?
        end
        render js: "alert('#{@product.errors[:base].join("\\n")}')" if @product.errors[:base].present?
      else
        @new_brand_name = Brand.select(:name).where(id: params[:product][:brand_id]).first.name
        @new_vendor_name = Vendor.select(:name).where(id: params[:product][:vendor_id]).first.name
        @new_model_name = Model.select(:name).where(id: params[:product][:model_id]).first.name
        @new_goods_type_name = GoodsType.select(:name).where(id: params[:product][:goods_type_id]).first.name
      end
    rescue ActiveRecord::RecordNotUnique => e
      #      size_group = SizeGroup.where(id: @product.size_group_id).select(:id).first
      #      @sizes = size_group ? size_group.sizes.select(:id, :size).order(:size) : []
      #      @price_codes = PriceCode.select(:id, :code).order :code
      #      @price_codes.each do |price_code|
      #        @sizes.each do |size|
      #          product_detail = @product.product_details.select{|pd| pd.price_code_id.eql?(price_code.id) and pd.size_id.eql?(size.id)}.first
      #          product_detail = @product.product_details.build(price_code_id: price_code.id, size_id: size.id) if product_detail.blank?
      #          price_list = product_detail.price_lists.select{|pl| pl.price.present?}
      #          product_detail.price_lists.build if price_list.blank?
      #        end
      #      end
      #      @colors = Color.select(:id, :code, :name).order(:code)
      #      @colors.each do |color|
      #        @product.product_colors.build color_id: color.id, code: color.code, name: color.name unless @product.product_colors.select{|product_color| product_color.color_id.eql?(color.id)}.present?
      #      end
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{products_url}'"
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
          @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size) : []
          @price_codes = PriceCode.select(:id, :code).order :code
          @price_codes.each do |price_code|
            @sizes.each do |size|
              product_detail = @product.product_details.select{|pd| pd.price_code_id.eql?(price_code.id) and pd.size_id.eql?(size.id)}.first
              product_detail = @product.product_details.build(price_code_id: price_code.id, size_id: size.id) if product_detail.nil?
              price_list = product_detail.price_lists.select{|pl| pl.price.present?}
              product_detail.price_lists.build if price_list.blank?
            end
          end
          @colors = Color.select(:id, :code, :name).order(:code)
          @colors.each do |color|
            product_color = @product.product_colors.select{|product_color| product_color.color_id.eql?(color.id)}.first
            if product_color
              product_color.selected_color_id = color.id
              product_color.code = color.code
              product_color.name = color.name
            else
              @product.product_colors.build color_id: color.id, code: color.code, name: color.name
            end      
          end
          if @product.errors[:base].present?
            flash.now[:alert] = @product.errors[:base].to_sentence
          end
          format.html { render :edit }
          format.json { render json: @product.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size) : []
        @price_codes = PriceCode.select(:id, :code).order :code
        @price_codes.each do |price_code|
          @sizes.each do |size|
            product_detail = @product.product_details.select{|pd| pd.price_code_id.eql?(price_code.id) and pd.size_id.eql?(size.id)}.first
            product_detail = @product.product_details.build(price_code_id: price_code.id, size_id: size.id) if product_detail.nil?
            price_list = product_detail.price_lists.select{|pl| pl.price.present?}
            product_detail.price_lists.build if price_list.blank?
          end
        end
        @colors = Color.select(:id, :code, :name).order(:code)
        @colors.each do |color|
          product_color = @product.product_colors.select{|product_color| product_color.color_id.eql?(color.id)}.first
          if product_color
            product_color.selected_color_id = color.id
            product_color.code = color.code
            product_color.name = color.name
          else
            @product.product_colors.build color_id: color.id, code: color.code, name: color.name
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
    @price_codes = PriceCode.select(:id, :code).order :code
    unless params[:product_id].present?
      @product = Product.new
      sg = SizeGroup.where(id: params[:id]).select(:id).first
      @sizes = sg.sizes.select(:id, :size).order(:size) if sg
      @price_codes.each do |price_code|
        @sizes.each do |size|
          product_detail = @product.product_details.build(price_code_id: price_code.id, size_id: size.id)
          product_detail.price_lists.build
        end
      end
    else
      @product = Product.where(id: params[:product_id]).select(:id, :size_group_id).first
      @product.size_group_id = params[:id]
      unless @product.size_group_id_changed?
        @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size) : []
      else        
        sg = SizeGroup.where(id: params[:id]).select(:id).first
        @sizes = sg.sizes.select(:id, :size).order(:size) if sg
        @price_codes.each do |price_code|
          @sizes.each do |size|
            product_detail = @product.product_details.build(price_code_id: price_code.id, size_id: size.id)
            product_detail.price_lists.build
          end
        end
      end
    end
    
    respond_to { |format| format.js }
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.joins(:brand, :vendor, :model, :goods_type).
      where(id: params[:id]).
      select("products.id, products.code, products.description, common_fields.code AS brand_code, vendors.code AS vendor_code, models_products.code AS model_code, goods_types_products.code AS goods_type_code, image, sex, target, size_group_id, brand_id, vendor_id, model_id, goods_type_id").first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:code, :description, :brand_id, :sex, :vendor_id,
      :target, :model_id, :effective_date,
      :goods_type_id, :image, :image_cache, :remove_image, :size_group_id,
      product_details_attributes: [:id, :size_id, :price_code_id, :price,
        price_lists_attributes: [:price, :effective_date]],
      cost_lists_attributes: [:effective_date, :cost, :is_user_creating_product],
      product_colors_attributes: [:id, :selected_color_id, :color_id, :code, :name, :_destroy]
    )
  end
  
  def convert_cost_price_to_numeric
    params[:product][:cost_lists_attributes].each do |key, value|
      params[:product][:cost_lists_attributes][key][:cost] = params[:product][:cost_lists_attributes][key][:cost].gsub("Rp","").gsub(".","").gsub(",",".")
    end if params[:product][:cost_lists_attributes].present?
    params[:product][:product_details_attributes].each do |key, value|
      params[:product][:product_details_attributes][key][:price_lists_attributes].each do |price_lists_key, value|
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:price] = params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:price].gsub("Rp","").gsub(".","").gsub(",",".")
      end if params[:product][:product_details_attributes][key][:price_lists_attributes].present?
    end if params[:product][:product_details_attributes].present?
  end
end
