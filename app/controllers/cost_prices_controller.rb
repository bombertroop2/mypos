include SmartListing::Helper::ControllerExtensions
class CostPricesController < ApplicationController
  helper SmartListing::Helper
  #  before_action :set_product, only: [:show, :edit, :update, :destroy, :new_cost, :create_cost, :edit_cost]
  #  before_action :convert_cost_price_to_numeric, only: [:create, :update, :create_cost]
  before_action :set_cost, only: [:show, :destroy]
  before_action :convert_cost_price_to_numeric, only: :update

  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_cost].present?
      params[:filter_cost] = params[:filter_cost].gsub("Rp","").gsub(".","").gsub(",",".").gsub(".00","")
    end
    if params[:filter_effective_date].present?
      splitted_date_range = params[:filter_effective_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end
    costs_scope = CostList.unscoped.joins(product: :brand).select("cost_lists.id, effective_date, cost, products.code, name, product_id")
    costs_scope = costs_scope.where(["products.code #{like_command} ?", "%"+params[:filter_product_code]+"%"]).
      or(costs_scope.where(["name #{like_command} ?", "%"+params[:filter_product_code]+"%"])) if params[:filter_product_code].present?
    costs_scope = costs_scope.where(["cost #{like_command} ?", "%"+params[:filter_cost]+"%"]) if params[:filter_cost].present?
    costs_scope = costs_scope.where(["DATE(effective_date) BETWEEN ? AND ?", start_date, end_date]) if params[:filter_effective_date].present?
    @costs = smart_listing_create(:costs, costs_scope, partial: 'cost_prices/listing', default_sort: {:"products.code" => "asc"})
  end

  def new
    @products = Product.joins(:brand).select("products.id, products.code, name").order "products.code"
    @cost = CostList.new
  end

  def create
    add_additional_params_to_child
    convert_cost_price_to_numeric
    @product = Product.where(id: params[:product][:id]).select(:id, :code, :brand_id, :sex, :vendor_id, :target, :model_id, :goods_type_id, :size_group_id).first
    params[:product].delete :id
    unless @product.update(product_params)
      @products = Product.joins(:brand).select("products.id, products.code, name").order "products.code"
      @price_codes = PriceCode.select(:id, :code).order :code
      size_group = SizeGroup.where(id: @product.size_group_id).select(:id).first
      @sizes = size_group ? size_group.sizes.select(:id, :size).order(:size) : []
    else
      effective_date = nil
      params[:product][:cost_lists_attributes].each do |key, value|
        effective_date = params[:product][:cost_lists_attributes][key][:effective_date]
      end if params[:product][:cost_lists_attributes].present?
      @cost = CostList.joins(product: :brand).select("cost_lists.id, effective_date, cost, products.code, name, product_id").where(["DATE(effective_date) = ? AND product_id = ?", effective_date.to_date, @product.id]).first
    end
  end

  def edit
    @cost = CostList.select(:id, :product_id, :effective_date).where(id: params[:id]).first
    @product = Product.joins(:brand).where(["products.id = ?", @cost.product_id]).select("products.id, size_group_id, products.code, name").first
    @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size) : []
    @price_codes = PriceCode.select(:id, :code).order :code
    @sizes.each do |size|
      @price_codes.each do |price_code|
        product_detail = @product.product_details.select("1 AS one").find_by(size_id: size.id, price_code_id: price_code.id)
        unless product_detail.present?
          product_detail = @product.product_details.build size_id: size.id, price_code_id: price_code.id
          product_detail.price_lists.build effective_date: @cost.effective_date
        end
      end 
    end
  end

  def update
    @cost = CostList.select(:id, :product_id, :cost, :effective_date).where(id: params[:id]).first
    @product = Product.joins(:brand).where(["products.id = ?", @cost.product_id]).select("products.id, products.code, products.brand_id, products.sex, products.vendor_id, products.target, products.model_id, products.goods_type_id, products.size_group_id, name").first
    unless @product.update(product_params)
      @price_codes = PriceCode.select(:id, :code).order :code
      size_group = SizeGroup.where(id: @product.size_group_id).select(:id).first
      @sizes = size_group ? size_group.sizes.select(:id, :size).order(:size) : []
    else
      effective_date = nil
      params[:product][:cost_lists_attributes].each do |key, value|
        effective_date = params[:product][:cost_lists_attributes][key][:effective_date]
      end if params[:product][:cost_lists_attributes].present?
      @cost = CostList.joins(product: :brand).select("cost_lists.id, effective_date, cost, products.code, name, product_id").where(["DATE(effective_date) = ? AND product_id = ?", effective_date.to_date, @product.id]).first
    end
  end

  def show
    #    @prices = Product.select(:id).where(id: @cost.product_id).first.prices.where(effective_date: @cost.effective_date)
    @price_codes = PriceCode.select(:id, :code).order :code
    @product = Product.select(:id, :size_group_id).where(id: @cost.product_id).first
    @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size) : []
  end

  def destroy
    @cost.user_is_deleting_from_child = true
    @cost.destroy    
    if @cost.errors.present? and @cost.errors.messages[:base].present?
      flash[:alert] = @cost.errors.messages[:base].to_sentence
      render js: "window.location = '/cost_prices'"
    end
  end
  
  def generate_form
    @product = Product.where(id: params[:product_id]).
      select("id, size_group_id").first
    @sizes = @product.size_group ? @product.size_group.sizes.select(:id, :size).order(:size) : []
    @price_codes = PriceCode.select(:id, :code).order :code
    @product.cost_lists.build
    @sizes.each do |size|
      @price_codes.each do |price_code|
        product_detail = @product.product_details.select{|pd| pd.size_id == size.id && pd.price_code_id == price_code.id}.first
        unless product_detail
          product_detail = @product.product_details.build size_id: size.id, price_code_id: price_code.id
        end
        product_detail.price_lists.build
      end 
    end
  end
  
  private
  
  # Never trust parameters from the scary internet, only allow the white list through.
  def product_params
    params.require(:product).permit(#:code, :description, :brand_id, :sex, :vendor_id,
      #:target, :model_id, :effective_date, :goods_type_id, :image, :image_cache, :remove_image,
      :size_group_id, :id,
      product_details_attributes: [:adding_new_price, :id, :size_id, :price_code_id,
        price_lists_attributes: [:editable_record, :turn_off_date_validation, :id, :price, :effective_date, :user_is_adding_price_from_cost_prices_page, :cost]],
      cost_lists_attributes: [:effective_date, :cost, :id])
  end

  
  def set_cost
    @cost = CostList.joins(product: :brand).select("name, cost_lists.id, effective_date, cost, products.id AS product_id, products.code").where(id: params[:id]).first
  end
  
  def convert_cost_price_to_numeric
    params[:product][:cost_lists_attributes].each do |key, value|
      params[:product][:cost_lists_attributes][key][:cost] = params[:product][:cost_lists_attributes][key][:cost].gsub("Rp","").gsub(".","").gsub(",",".")
    end if params[:product][:cost_lists_attributes].present?
    params[:product][:product_details_attributes].each do |key, value|
      params[:product][:product_details_attributes][key][:price_lists_attributes].each do |price_lists_key, value|
        next if params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key].length == 1 && params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:id].present?
        next if params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key].length == 2 && params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:id].present? && params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:turn_off_date_validation].present?
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:price] = params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:price].gsub("Rp","").gsub(".","").gsub(",",".")
        params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:cost] = params[:product][:product_details_attributes][key][:price_lists_attributes][price_lists_key][:cost].gsub("Rp","").gsub(".","").gsub(",",".")
      end if params[:product][:product_details_attributes][key][:price_lists_attributes].present?
    end if params[:product][:product_details_attributes].present?
  end
  
  def add_additional_params_to_child
    effective_date = ""
    cost = ""
    params[:product][:cost_lists_attributes].each do |key, value|
      effective_date = params[:product][:cost_lists_attributes][key][:effective_date]
      cost = params[:product][:cost_lists_attributes][key][:cost]
    end if params[:product][:cost_lists_attributes].present?
        
    params[:product][:product_details_attributes].each do |key, value|
      # tambahkan apabila membuat price baru
      unless params[:product][:product_details_attributes][key][:id].present?
        params[:product][:product_details_attributes][key].merge! adding_new_price: true
      end
      
      params[:product][:product_details_attributes][key][:price_lists_attributes].each do |price_list_key, value|
        # tambahkan apabila membuat price baru
        unless params[:product][:product_details_attributes][key][:price_lists_attributes][price_list_key][:id].present?
          params[:product][:product_details_attributes][key][:price_lists_attributes][price_list_key].merge! effective_date: effective_date, cost: cost, user_is_adding_price_from_cost_prices_page: true
        end
      end if params[:product][:product_details_attributes][key][:price_lists_attributes].present?
    end if params[:product][:product_details_attributes].present?
  end

end
