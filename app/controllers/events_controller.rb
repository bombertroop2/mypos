include SmartListing::Helper::ControllerExtensions
class EventsController < ApplicationController
  helper SmartListing::Helper
  load_and_authorize_resource
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  # GET /events
  # GET /events.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end

    if params[:filter_event_start_time].present?
      splitted_start_time_range = params[:filter_event_start_time].split("-")
      start_start_time = Time.zone.parse splitted_start_time_range[0].strip
      end_start_time = Time.zone.parse splitted_start_time_range[1].strip
    end

    if params[:filter_event_end_time].present?
      splitted_end_time_range = params[:filter_event_end_time].split("-")
      start_end_time = Time.zone.parse splitted_end_time_range[0].strip
      end_end_time = Time.zone.parse splitted_end_time_range[1].strip
    end

    events_scope = Event.select(:id, :code, :name, :start_date_time, :end_date_time, :event_type)
    events_scope = events_scope.where(["code #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(events_scope.where(["name #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string]
    events_scope = events_scope.where(["start_date_time BETWEEN ? AND ?", start_start_time, end_start_time]) if params[:filter_event_start_time].present?
    events_scope = events_scope.where(["end_date_time BETWEEN ? AND ?", start_end_time, end_end_time]) if params[:filter_event_end_time].present?
    @events = smart_listing_create(:events, events_scope, partial: 'events/listing', default_sort: {event_type: "asc"})
  end

  # GET /events/1
  # GET /events/1.json
  def show
  end

  # GET /events/new
  def new
    @warehouses = Warehouse.select(:id, :code, :name).actived.not_central.order(:code)
    @event = Event.new
    @brands = Brand.select(:id, :code, :name).order(:code)
    @goods_types = GoodsType.select(:id, :code, :name).order(:code)
    @models = Model.select(:id, :code, :name).order(:code)
  end

  # GET /events/1/edit
  def edit
    @event.start_date_time = @event.start_date_time.strftime("%d/%m/%Y %H:%M")
    @event.end_date_time = @event.end_date_time.strftime("%d/%m/%Y %H:%M")
    @warehouses = Warehouse.select(:id, :code, :name).actived.not_central.order(:code)
    @brands = Brand.select(:id, :code, :name).order(:code)
    @goods_types = GoodsType.select(:id, :code, :name).order(:code)
    @models = Model.select(:id, :code, :name).order(:code)
  end

  # POST /events
  # POST /events.json
  def create
    remove_warehouse_products
    params[:event][:cash_discount] = params[:event][:cash_discount].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:event][:cash_discount].present?
    params[:event][:special_price] = params[:event][:special_price].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:event][:special_price].present?
    convert_amount_fields_to_numeric
    @event = Event.new(event_params)
    
    begin
      @valid = @event.save
      unless @valid
        @warehouses = Warehouse.select(:id, :code, :name).actived.not_central.order(:code)
        @brands = Brand.select(:id, :code, :name).order(:code)
        @goods_types = GoodsType.select(:id, :code, :name).order(:code)
        @models = Model.select(:id, :code, :name).order(:code)
      end
    rescue ActiveRecord::RecordNotUnique => e
      @valid = false
      @event.errors.messages[:code] = ["has already been taken"]
      @warehouses = Warehouse.select(:id, :code, :name).actived.not_central.order(:code)
      @brands = Brand.select(:id, :code, :name).order(:code)
      @goods_types = GoodsType.select(:id, :code, :name).order(:code)
      @models = Model.select(:id, :code, :name).order(:code)
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    remove_warehouse_products
    params[:event][:cash_discount] = params[:event][:cash_discount].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:event][:cash_discount].present?
    params[:event][:special_price] = params[:event][:special_price].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:event][:special_price].present?
    convert_amount_fields_to_numeric
    begin
      @valid = @event.update(event_params)
      unless @valid
        @warehouses = Warehouse.select(:id, :code, :name).actived.not_central.order(:code)
        @brands = Brand.select(:id, :code, :name).order(:code)
        @goods_types = GoodsType.select(:id, :code, :name).order(:code)
        @models = Model.select(:id, :code, :name).order(:code)
      end
    rescue ActiveRecord::RecordNotUnique => e
      @valid = false
      @event.errors.messages[:code] = ["has already been taken"]
      @warehouses = Warehouse.select(:id, :code, :name).actived.not_central.order(:code)
      @brands = Brand.select(:id, :code, :name).order(:code)
      @goods_types = GoodsType.select(:id, :code, :name).order(:code)
      @models = Model.select(:id, :code, :name).order(:code)
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    unless @event.destroy
      @deleted = false
    else
      @deleted = true
    end
  end
  
  def generate_warehouse_form
    @event = if params[:event_id].present?
      Event.where(["id = ?", params[:event_id]]).select(:id).first
    else
      Event.new
    end
    warehouse_ids = params[:warehouse_ids].split(",")
    warehouses = Warehouse.where(id: warehouse_ids).actived.not_central.select(:id, :code, :name)
    
    unless @event.new_record?
      @event_warehouses = []
      event_warehouses = @event.event_warehouses.joins(:warehouse).select(:id, :warehouse_id, :code, :name, :select_different_products)
      event_warehouses.each do |ew|
        unless warehouse_ids.include?(ew.warehouse_id.to_s)
          ew.remove = true
        else
          ew.wrhs_code = ew.code
          ew.wrhs_name = ew.name
        end
        @event_warehouses << ew
      end
    end
    
    warehouses.each do |warehouse|        
      unless params[:event_type].eql?("gift")
        unless @event.new_record?
          if @event_warehouses.select{|ew| ew.warehouse_id == warehouse.id}.empty?
            @event_warehouses << @event.event_warehouses.build(warehouse_id: warehouse.id, wrhs_code: warehouse.code, wrhs_name: warehouse.name)
          end
        else
          @event.event_warehouses.build warehouse_id: warehouse.id, wrhs_code: warehouse.code, wrhs_name: warehouse.name
        end
      else
        unless @event.new_record?
          if @event_warehouses.select{|ew| ew.warehouse_id == warehouse.id}.empty?
            @event_warehouses << @event.event_warehouses.build(warehouse_id: warehouse.id, wrhs_code: warehouse.code, wrhs_name: warehouse.name, event_type: "gift")
          end
        else
          @event.event_warehouses.build warehouse_id: warehouse.id, wrhs_code: warehouse.code, wrhs_name: warehouse.name, event_type: "gift"
        end
      end
    end
    @brands = Brand.select(:id, :code, :name).order(:code)
    @goods_types = GoodsType.select(:id, :code, :name).order(:code)
    @models = Model.select(:id, :code, :name).order(:code)
  end
  
  def add_products
    if params[:product_code].blank?
      products = Product.joins(:brand, :goods_type, :model).
        select("products.id, products.code AS product_code, common_fields.name AS product_name")
      if params[:brand_id].blank? && params[:goods_type_id].blank? && params[:model_id].blank?      
        products = products.where(["products.id NOT IN (?)", params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
      elsif params[:brand_id].present? && params[:goods_type_id].blank? && params[:model_id].blank?      
        products = products.where(["brand_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["brand_id = ?", params[:brand_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].blank? && params[:goods_type_id].present? && params[:model_id].blank?      
        products = products.where(["goods_type_id = ? AND products.id NOT IN (?)", params[:goods_type_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["goods_type_id = ?", params[:goods_type_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].blank? && params[:goods_type_id].blank? && params[:model_id].present?      
        products = products.where(["model_id = ? AND products.id NOT IN (?)", params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["model_id = ?", params[:model_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].present? && params[:goods_type_id].present? && params[:model_id].blank?      
        products = products.where(["brand_id = ? AND goods_type_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:goods_type_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["brand_id = ? AND goods_type_id = ?", params[:brand_id], params[:goods_type_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].present? && params[:goods_type_id].blank? && params[:model_id].present?      
        products = products.where(["brand_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["brand_id = ? AND model_id = ?", params[:brand_id], params[:model_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].blank? && params[:goods_type_id].present? && params[:model_id].present?      
        products = products.where(["goods_type_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:goods_type_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["goods_type_id = ? AND model_id = ?", params[:goods_type_id], params[:model_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].present? && params[:goods_type_id].present? && params[:model_id].present?      
        products = products.where(["brand_id = ? AND goods_type_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:goods_type_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["brand_id = ? AND goods_type_id = ? AND model_id = ?", params[:brand_id], params[:goods_type_id], params[:model_id]]) if params[:selected_product_ids].blank?
      end
    else
      products = Product.joins(:brand).
        select("products.id, products.code AS product_code, common_fields.name AS product_name").
        where(["products.code = ?", params[:product_code]]) if params[:selected_product_ids].blank?
      products = Product.joins(:brand).
        select("products.id, products.code AS product_code, common_fields.name AS product_name").
        where(["products.code = ? AND products.id NOT IN (?)", params[:product_code], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
    end
    if products.blank?
      render js: "bootbox.alert({message: \"No records found or already added to the list\",size: 'small'});"
    else
      @products = products
      @event = if params[:event_id].blank?
        Event.new
      else
        Event.where(id: params[:event_id]).select(:id).first
      end
      @event_warehouse = if @event.new_record?
        @event.event_warehouses.build warehouse_id: params[:warehouse_id]
      else
        ew = @event.event_warehouses.where(warehouse_id: params[:warehouse_id]).select(:id, :warehouse_id).first
        if ew.blank?
          @event.event_warehouses.build warehouse_id: params[:warehouse_id]
        else
          ew
        end
      end
      @existing_event_new_products = []
      products.each do |product|
        if !@event.new_record? && @event_warehouse.event_products.where(product_id: product.id).select("1 AS one").blank?
          @existing_event_new_products << @event_warehouse.event_products.build(product_id: product.id, prdct_code: product.product_code, prdct_name: product.product_name)
        elsif @event.new_record?
          @event_warehouse.event_products.build product_id: product.id, prdct_code: product.product_code, prdct_name: product.product_name
        end
      end
    end
  end
  
  def add_general_products
    if params[:product_code].blank?
      products = Product.joins(:brand, :goods_type, :model).
        select("products.id, products.code AS product_code, common_fields.name AS product_name")
      if params[:brand_id].blank? && params[:goods_type_id].blank? && params[:model_id].blank?      
        products = products.where(["products.id NOT IN (?)", params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
      elsif params[:brand_id].present? && params[:goods_type_id].blank? && params[:model_id].blank?      
        products = products.where(["brand_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["brand_id = ?", params[:brand_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].blank? && params[:goods_type_id].present? && params[:model_id].blank?      
        products = products.where(["goods_type_id = ? AND products.id NOT IN (?)", params[:goods_type_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["goods_type_id = ?", params[:goods_type_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].blank? && params[:goods_type_id].blank? && params[:model_id].present?      
        products = products.where(["model_id = ? AND products.id NOT IN (?)", params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["model_id = ?", params[:model_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].present? && params[:goods_type_id].present? && params[:model_id].blank?      
        products = products.where(["brand_id = ? AND goods_type_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:goods_type_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["brand_id = ? AND goods_type_id = ?", params[:brand_id], params[:goods_type_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].present? && params[:goods_type_id].blank? && params[:model_id].present?      
        products = products.where(["brand_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["brand_id = ? AND model_id = ?", params[:brand_id], params[:model_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].blank? && params[:goods_type_id].present? && params[:model_id].present?      
        products = products.where(["goods_type_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:goods_type_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["goods_type_id = ? AND model_id = ?", params[:goods_type_id], params[:model_id]]) if params[:selected_product_ids].blank?
      elsif params[:brand_id].present? && params[:goods_type_id].present? && params[:model_id].present?      
        products = products.where(["brand_id = ? AND goods_type_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:goods_type_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
        products = products.where(["brand_id = ? AND goods_type_id = ? AND model_id = ?", params[:brand_id], params[:goods_type_id], params[:model_id]]) if params[:selected_product_ids].blank?
      end
    else
      products = Product.joins(:brand).
        select("products.id, products.code AS product_code, common_fields.name AS product_name").
        where(["products.code = ?", params[:product_code]]) if params[:selected_product_ids].blank?
      products = Product.joins(:brand).
        select("products.id, products.code AS product_code, common_fields.name AS product_name").
        where(["products.code = ? AND products.id NOT IN (?)", params[:product_code], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
    end
    if products.blank?
      render js: "bootbox.alert({message: \"No records found or already added to the list\",size: 'small'});"
    else
      @products = products
      @event = if params[:event_id].blank?
        Event.new
      else
        Event.where(id: params[:event_id]).select(:id).first
      end
      @existing_event_new_general_products = []
      products.each do |product|
        @existing_event_new_general_products << @event.event_general_products.build(product_id: product.id, prdct_code: product.product_code, prdct_name: product.product_name) if (!@event.new_record? && @event.event_general_products.where(product_id: product.id).select("1 AS one").blank?) || @event.new_record?
      end
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def event_params
    params.require(:event).permit(:is_active, :minimum_purchase_amount, :discount_amount, :code, :name, :start_date_time, :end_date_time, :first_plus_discount, :second_plus_discount, :event_type, :cash_discount, :special_price,
      event_general_products_attributes: [:id, :_destroy, :product_id, :prdct_code, :prdct_name],
      event_warehouses_attributes: [:_destroy, :id, :event_type, :warehouse_id,
        :wrhs_code, :wrhs_name, :select_different_products,
        event_products_attributes: [:id, :product_id, :prdct_code, :prdct_name, :_destroy]])
  end
  
  def convert_amount_fields_to_numeric
    params[:event][:minimum_purchase_amount] = params[:event][:minimum_purchase_amount].gsub("Rp","").gsub(".","").gsub(",",".") if params[:event][:minimum_purchase_amount].present?
    params[:event][:discount_amount] = params[:event][:discount_amount].gsub("Rp","").gsub(".","").gsub(",",".") if params[:event][:discount_amount].present?
  end

  def remove_warehouse_products
    params[:event][:event_warehouses_attributes].each do |key, value|
      if params[:event][:event_warehouses_attributes][key][:select_different_products].eql?("0")
        params[:event][:event_warehouses_attributes][key][:event_products_attributes].each do |ep_key, ep_value|
          if params[:event][:event_warehouses_attributes][key][:event_products_attributes][ep_key][:id].present?
            params[:event][:event_warehouses_attributes][key][:event_products_attributes][ep_key][:_destroy] = "true"
          else
            params[:event][:event_warehouses_attributes][key][:event_products_attributes].delete ep_key
          end
        end if params[:event][:event_warehouses_attributes][key][:event_products_attributes].present?
      end
    end if params[:event][:event_warehouses_attributes].present?
  end
end
