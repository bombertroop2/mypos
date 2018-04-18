include SmartListing::Helper::ControllerExtensions
class ProductsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource except: :populate_detail_form
  before_action :set_product, only: [:show, :edit, :update, :destroy]

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
    if @colors.size == 0
      render js: "bootbox.alert({message: \"Please create color first\",size: 'small'});"
    elsif PriceCode.count(:id) == 0
      render js: "bootbox.alert({message: \"Please create price code first\",size: 'small'});"
    elsif SizeGroup.count(:id) == 0
      render js: "bootbox.alert({message: \"Please create size group first\",size: 'small'});"
    end
  end

  # GET /products/1/edit
  def edit
    #    @product.effective_date = @product.active_effective_date.strftime("%d/%m/%Y")
    @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size_order) : []
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
    add_additional_params_to_product_details(true)
    add_additional_params_to_price_lists("create")
    add_additional_param_to_cost_lists(true)
    convert_cost_price_to_numeric
    @product = Product.new(product_params)
    begin
      unless @product.save       
        size_group = SizeGroup.where(id: @product.size_group_id).select(:id).first
        @sizes = size_group ? size_group.sizes.select(:id, :size).order(:size_order) : []
        @price_codes = PriceCode.select(:id, :code).order :code
        @colors = Color.select(:id, :code, :name).order(:code)
        @colors.each do |color|
          @product.product_colors.build color_id: color.id, code: color.code, name: color.name unless @product.product_colors.select{|product_color| product_color.color_id.eql?(color.id)}.present?
        end
        render js: "bootbox.alert({message: \"#{@product.errors[:base].join("\\n")}\",size: 'small'});" if @product.errors[:base].present?        
      else
        @new_brand_name = Brand.select(:name).where(id: params[:product][:brand_id]).first.name
        @new_vendor_name = Vendor.select(:name).where(id: params[:product][:vendor_id]).first.name
        @new_model_name = Model.select(:name).where(id: params[:product][:model_id]).first.name
        @new_goods_type_name = GoodsType.select(:name).where(id: params[:product][:goods_type_id]).first.name
      end
    rescue ActiveRecord::RecordNotUnique => e
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{products_url}'"
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    add_additional_params_to_product_details(false)
    add_additional_params_to_price_lists("update")
    add_additional_param_to_cost_lists(false)
    convert_cost_price_to_numeric
    begin        
      unless @product.update(product_params)
        if @product.errors[:"product_colors.base"].present?
          render js: "bootbox.alert({message: \"#{@product.errors[:"product_colors.base"].join("<br/>")}\",size: 'small'});"
        else
          @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size_order) : []
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
      else
        @new_brand_name = Brand.select(:name).where(id: params[:product][:brand_id]).first.name
        @new_vendor_name = Vendor.select(:name).where(id: params[:product][:vendor_id]).first.name
        @new_model_name = Model.select(:name).where(id: params[:product][:model_id]).first.name
        @new_goods_type_name = GoodsType.select(:name).where(id: params[:product][:goods_type_id]).first.name
      end
    rescue ActiveRecord::RecordNotUnique => e   
      flash[:alert] = "That code has already been taken"
      render js: "window.location = '#{products_url}'"
    rescue ActiveRecord::RecordNotDestroyed => e
      render js: "bootbox.alert({message: \"Sorry, you can't change colors!\",size: 'small'});"
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy    
    @product.destroy    
    if @product.errors.present? and @product.errors.messages[:base].present?
      error_message = @product.errors.messages[:base].to_sentence
      error_message.slice! "products "
      flash[:alert] = error_message
      render js: "window.location = '#{products_url}'"
    end
  end
  
  def populate_detail_form
    @price_codes = PriceCode.select(:id, :code).order :code
    unless params[:product_id].present?
      @product = Product.new
      sg = SizeGroup.where(id: params[:id]).select(:id).first
      @sizes = sg.sizes.select(:id, :size).order(:size_order) if sg
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
        @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size_order) : []
      else        
        sg = SizeGroup.where(id: params[:id]).select(:id).first
        @sizes = sg.sizes.select(:id, :size).order(:size_order) if sg
        #        @price_codes.each do |price_code|
        #          @sizes.each do |size|
        #            product_detail = @product.product_details.build(price_code_id: price_code.id, size_id: size.id)
        #            product_detail.price_lists.build
        #          end
        #        end
      end
    end
    
    respond_to { |format| format.js }
  end
  
  private
  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.joins(:brand, :vendor, :model, :goods_type).
      where(id: params[:id]).
      select("products.id, products.code, products.description, common_fields.name AS brand_name, vendors.code AS vendor_code, models_products.code AS model_code, goods_types_products.code AS goods_type_code, image, sex, target, size_group_id, brand_id, vendor_id, model_id, goods_type_id").first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(:code, :description, :brand_id, :sex, :vendor_id,
      :target, :model_id,# :effective_date,
      :goods_type_id, :image, :image_cache, :remove_image, :size_group_id,
      product_details_attributes: [:id, :size_id, :price_code_id, :price, :user_is_adding_new_product, :size_group_id,
        price_lists_attributes: [:id, :price, :user_is_adding_new_price, :cost, :product_id]],
      cost_lists_attributes: [:id, :cost, :is_user_creating_product],
      product_colors_attributes: [:id, :selected_color_id, :color_id, :code, :name, :_destroy]
    )
  end
  

  def convert_cost_price_to_numeric
    params[:product][:cost_lists_attributes].each do |key, value|
      params[:product][:cost_lists_attributes][key][:cost] = params[:product][:cost_lists_attributes][key][:cost].gsub("Rp","").gsub(".","").gsub(",",".") if params[:product][:cost_lists_attributes][key][:cost].present?
    end if params[:product][:cost_lists_attributes].present?
    params[:product][:product_details_attributes].each do |key, value|
      params[:product][:product_details_attributes][key][:price_lists_attributes].each do |price_lists_key, value|
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:price] = params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:price].gsub("Rp","").gsub(".","").gsub(",",".")
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:cost] = params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:cost].gsub("Rp","").gsub(".","").gsub(",",".")
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:product_id] = @product.id if @product.present? && !@product.new_record?
      end if params[:product][:product_details_attributes][key][:price_lists_attributes].present?
    end if params[:product][:product_details_attributes].present?
  end
  
  def add_additional_params_to_product_details(status)
    params[:product][:product_details_attributes].each do |key, value|
      params[:product][:product_details_attributes][key].merge! size_group_id: params[:product][:size_group_id], user_is_adding_new_product: status
    end if params[:product][:product_details_attributes].present?
  end
   
  def add_additional_params_to_price_lists(action)
    # ambil cost
    cost = ""
    params[:product][:cost_lists_attributes].each do |key, value|
      cost = params[:product][:cost_lists_attributes][key][:cost]
    end if params[:product][:cost_lists_attributes].present?
    
    params[:product][:product_details_attributes].each do |key, value|
      params[:product][:product_details_attributes][key][:price_lists_attributes].each do |price_lists_key, value|
        if action.eql?("create")
          params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key].merge! user_is_adding_new_price: true
        else
          if params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:id].present?
            params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key].merge! user_is_adding_new_price: false
          else
            params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key].merge! user_is_adding_new_price: true
          end
        end
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:cost] = cost
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:product_id] = params[:id] if action.eql?("update")
      end if params[:product][:product_details_attributes][key][:price_lists_attributes].present?
    end if params[:product][:product_details_attributes].present?
  end
  
  def add_additional_param_to_cost_lists(status)
    params[:product][:cost_lists_attributes].each do |key, value|
      params[:product][:cost_lists_attributes][key].merge! is_user_creating_product: status
    end if params[:product][:cost_lists_attributes].present?
  end
end
