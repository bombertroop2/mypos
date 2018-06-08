#include SmartListing::Helper::ControllerExtensions
#class CounterEventsController < ApplicationController
#  helper SmartListing::Helper
#  authorize_resource
#  before_action :set_counter_event, only: [:show, :edit, :update, :destroy, :generate_activation_form, :activate_deactivate]
#
#  # GET /counter_events
#  # GET /counter_events.json
#  def index
#    like_command = if Rails.env.eql?("production")
#      "ILIKE"
#    else
#      "LIKE"
#    end
#
#    if params[:filter_counter_event_start_time].present?
#      splitted_start_time_range = params[:filter_counter_event_start_time].split("-")
#      start_start_time = Time.zone.parse splitted_start_time_range[0].strip
#      end_start_time = Time.zone.parse splitted_start_time_range[1].strip
#    end
#
#    if params[:filter_counter_event_end_time].present?
#      splitted_end_time_range = params[:filter_counter_event_end_time].split("-")
#      start_end_time = Time.zone.parse splitted_end_time_range[0].strip
#      end_end_time = Time.zone.parse splitted_end_time_range[1].strip
#    end
#
#    counter_events_scope = CounterEvent.select(:id, :code, :name, :start_date_time, :end_date_time, :counter_event_type, :is_active)
#    counter_events_scope = counter_events_scope.where(["code #{like_command} ?", "%"+params[:filter_string]+"%"]).
#      or(counter_events_scope.where(["name #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string]
#    counter_events_scope = counter_events_scope.where(["start_date_time BETWEEN ? AND ?", start_start_time, end_start_time]) if params[:filter_counter_event_start_time].present?
#    counter_events_scope = counter_events_scope.where(["end_date_time BETWEEN ? AND ?", start_end_time, end_end_time]) if params[:filter_counter_event_end_time].present?
#    @counter_events = smart_listing_create(:counter_events, counter_events_scope, partial: 'counter_events/listing', default_sort: {counter_event_type: "asc"})
#  end
#
#  # GET /counter_events/1
#  # GET /counter_events/1.json
#  def show
#  end
#
#  # GET /counter_events/new
#  def new
#    @warehouses = Warehouse.select(:id, :code, :name).actived.showroom.order(:code)
#    @counter_event = CounterEvent.new
#    @brands = Brand.select(:id, :code, :name).order(:code)
#    @goods_types = GoodsType.select(:id, :code, :name).order(:code)
#    @models = Model.select(:id, :code, :name).order(:code)
#  end
#
#  # GET /counter_events/1/edit
#  def edit
#    @counter_event.start_date_time = @counter_event.start_date_time.strftime("%d/%m/%Y %H:%M")
#    @counter_event.end_date_time = @counter_event.end_date_time.strftime("%d/%m/%Y %H:%M")
#    @warehouses = Warehouse.select(:id, :code, :name).actived.showroom.order(:code)
#    @brands = Brand.select(:id, :code, :name).order(:code)
#    @goods_types = GoodsType.select(:id, :code, :name).order(:code)
#    @models = Model.select(:id, :code, :name).order(:code)
#  end
#
#  # POST /counter_events
#  # POST /counter_events.json
#  def create
#    remove_warehouse_products
#    params[:counter_event][:cash_discount] = params[:counter_event][:cash_discount].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:counter_event][:cash_discount].present?
#    params[:counter_event][:special_price] = params[:counter_event][:special_price].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:counter_event][:special_price].present?
#    convert_amount_fields_to_numeric
#    @counter_event = CounterEvent.new(counter_event_params)
#    
#    begin
#      @valid = @counter_event.save
#      unless @valid
#        if @counter_event.errors[:base].present?
#          render js: "bootbox.alert({message: \"#{@counter_event.errors[:base].join("<br/>")}\",size: 'small'});"
#        else
#          @warehouses = Warehouse.select(:id, :code, :name).actived.showroom.order(:code)
#          @brands = Brand.select(:id, :code, :name).order(:code)
#          @goods_types = GoodsType.select(:id, :code, :name).order(:code)
#          @models = Model.select(:id, :code, :name).order(:code)
#        end
#      end
#    rescue ActiveRecord::RecordNotUnique => e
#      @valid = false
#      @counter_event.errors.messages[:code] = ["has already been taken"]
#      @warehouses = Warehouse.select(:id, :code, :name).actived.showroom.order(:code)
#      @brands = Brand.select(:id, :code, :name).order(:code)
#      @goods_types = GoodsType.select(:id, :code, :name).order(:code)
#      @models = Model.select(:id, :code, :name).order(:code)
#    end
#  end
#
#  # PATCH/PUT /counter_events/1
#  # PATCH/PUT /counter_events/1.json
#  def update
#    remove_warehouse_products
#    params[:counter_event][:cash_discount] = params[:counter_event][:cash_discount].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:counter_event][:cash_discount].present?
#    params[:counter_event][:special_price] = params[:counter_event][:special_price].gsub("Rp","").gsub(".","").gsub(",",".").gsub("-","") if params[:counter_event][:special_price].present?
#    convert_amount_fields_to_numeric
#    begin
#      @valid = @counter_event.update(counter_event_params)
#      unless @valid
#        unless @counter_event.errors[:base].present?
#          @warehouses = Warehouse.select(:id, :code, :name).actived.showroom.order(:code)
#          @brands = Brand.select(:id, :code, :name).order(:code)
#          @goods_types = GoodsType.select(:id, :code, :name).order(:code)
#          @models = Model.select(:id, :code, :name).order(:code)
#        else
#          render js: "bootbox.alert({message: \"#{@counter_event.errors[:base].join("<br/>")}\",size: 'small'});"
#        end
#      end
#    rescue ActiveRecord::RecordNotUnique => e
#      @valid = false
#      @counter_event.errors.messages[:code] = ["has already been taken"]
#      @warehouses = Warehouse.select(:id, :code, :name).actived.showroom.order(:code)
#      @brands = Brand.select(:id, :code, :name).order(:code)
#      @goods_types = GoodsType.select(:id, :code, :name).order(:code)
#      @models = Model.select(:id, :code, :name).order(:code)
#    end
#  end
#
#  # DELETE /counter_events/1
#  # DELETE /counter_events/1.json
#  def destroy
#    unless @counter_event.destroy
#      @deleted = false
#    else
#      @deleted = true
#    end
#  end
#  
#  def generate_warehouse_form
#    @counter_event = if params[:counter_event_id].present?
#      CounterEvent.where(["id = ?", params[:counter_event_id]]).select(:id).first
#    else
#      CounterEvent.new
#    end
#    warehouse_ids = params[:warehouse_ids].split(",")
#    warehouses = Warehouse.where(id: warehouse_ids).actived.showroom.select(:id, :code, :name)
#    
#    unless @counter_event.new_record?
#      @counter_event_warehouses = []
#      counter_event_warehouses = @counter_event.counter_event_warehouses.joins(:warehouse).select(:id, :warehouse_id, :code, :name, :select_different_products).where(["warehouses.is_active = ?", true])
#      counter_event_warehouses.each do |ew|
#        unless warehouse_ids.include?(ew.warehouse_id.to_s)
#          ew.remove = true
#        else
#          ew.wrhs_code = ew.code
#          ew.wrhs_name = ew.name
#        end
#        @counter_event_warehouses << ew
#      end
#    end
#    
#    warehouses.each do |warehouse|        
#      unless params[:counter_event_type].eql?("gift")
#        unless @counter_event.new_record?
#          if @counter_event_warehouses.select{|ew| ew.warehouse_id == warehouse.id}.empty?
#            @counter_event_warehouses << @counter_event.counter_event_warehouses.build(warehouse_id: warehouse.id, wrhs_code: warehouse.code, wrhs_name: warehouse.name)
#          end
#        else
#          @counter_event.counter_event_warehouses.build warehouse_id: warehouse.id, wrhs_code: warehouse.code, wrhs_name: warehouse.name
#        end
#      else
#        unless @counter_event.new_record?
#          if @counter_event_warehouses.select{|ew| ew.warehouse_id == warehouse.id}.empty?
#            @counter_event_warehouses << @counter_event.counter_event_warehouses.build(warehouse_id: warehouse.id, wrhs_code: warehouse.code, wrhs_name: warehouse.name, counter_event_type: "gift")
#          end
#        else
#          @counter_event.counter_event_warehouses.build warehouse_id: warehouse.id, wrhs_code: warehouse.code, wrhs_name: warehouse.name, counter_event_type: "gift"
#        end
#      end
#    end
#    @brands = Brand.select(:id, :code, :name).order(:code)
#    @goods_types = GoodsType.select(:id, :code, :name).order(:code)
#    @models = Model.select(:id, :code, :name).order(:code)
#  end
#  
#  def add_products
#    if params[:product_code].blank?
#      products = Product.joins(:brand, :goods_type, :model).
#        select("products.id, products.code AS product_code, common_fields.name AS product_name")
#      if params[:brand_id].blank? && params[:goods_type_id].blank? && params[:model_id].blank?      
#        products = products.where(["products.id NOT IN (?)", params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#      elsif params[:brand_id].present? && params[:goods_type_id].blank? && params[:model_id].blank?      
#        products = products.where(["brand_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["brand_id = ?", params[:brand_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].blank? && params[:goods_type_id].present? && params[:model_id].blank?      
#        products = products.where(["goods_type_id = ? AND products.id NOT IN (?)", params[:goods_type_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["goods_type_id = ?", params[:goods_type_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].blank? && params[:goods_type_id].blank? && params[:model_id].present?      
#        products = products.where(["model_id = ? AND products.id NOT IN (?)", params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["model_id = ?", params[:model_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].present? && params[:goods_type_id].present? && params[:model_id].blank?      
#        products = products.where(["brand_id = ? AND goods_type_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:goods_type_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["brand_id = ? AND goods_type_id = ?", params[:brand_id], params[:goods_type_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].present? && params[:goods_type_id].blank? && params[:model_id].present?      
#        products = products.where(["brand_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["brand_id = ? AND model_id = ?", params[:brand_id], params[:model_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].blank? && params[:goods_type_id].present? && params[:model_id].present?      
#        products = products.where(["goods_type_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:goods_type_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["goods_type_id = ? AND model_id = ?", params[:goods_type_id], params[:model_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].present? && params[:goods_type_id].present? && params[:model_id].present?      
#        products = products.where(["brand_id = ? AND goods_type_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:goods_type_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["brand_id = ? AND goods_type_id = ? AND model_id = ?", params[:brand_id], params[:goods_type_id], params[:model_id]]) if params[:selected_product_ids].blank?
#      end
#    else
#      products = Product.joins(:brand).
#        select("products.id, products.code AS product_code, common_fields.name AS product_name").
#        where(["products.code = ?", params[:product_code]]) if params[:selected_product_ids].blank?
#      products = Product.joins(:brand).
#        select("products.id, products.code AS product_code, common_fields.name AS product_name").
#        where(["products.code = ? AND products.id NOT IN (?)", params[:product_code], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#    end
#    if products.blank?
#      render js: "bootbox.alert({message: \"No records found or already added to the list\",size: 'small'});"
#    else
#      @products = products
#      @counter_event = if params[:counter_event_id].blank?
#        CounterEvent.new
#      else
#        CounterEvent.where(id: params[:counter_event_id]).select(:id).first
#      end
#      @counter_event_warehouse = if @counter_event.new_record?
#        @counter_event.counter_event_warehouses.build warehouse_id: params[:warehouse_id]
#      else
#        ew = @counter_event.counter_event_warehouses.where(warehouse_id: params[:warehouse_id]).select(:id, :warehouse_id).first
#        if ew.blank?
#          @counter_event.counter_event_warehouses.build warehouse_id: params[:warehouse_id]
#        else
#          ew
#        end
#      end
#      @existing_counter_event_new_products = []
#      products.each do |product|
#        if !@counter_event.new_record? && @counter_event_warehouse.counter_event_products.where(product_id: product.id).select("1 AS one").blank?
#          @existing_counter_event_new_products << @counter_event_warehouse.counter_event_products.build(product_id: product.id, prdct_code: product.product_code, prdct_name: product.product_name)
#        elsif @counter_event.new_record?
#          @counter_event_warehouse.counter_event_products.build product_id: product.id, prdct_code: product.product_code, prdct_name: product.product_name
#        end
#      end
#    end
#  end
#  
#  def add_general_products
#    if params[:product_code].blank?
#      products = Product.joins(:brand, :goods_type, :model).
#        select("products.id, products.code AS product_code, common_fields.name AS product_name")
#      if params[:brand_id].blank? && params[:goods_type_id].blank? && params[:model_id].blank?      
#        products = products.where(["products.id NOT IN (?)", params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#      elsif params[:brand_id].present? && params[:goods_type_id].blank? && params[:model_id].blank?      
#        products = products.where(["brand_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["brand_id = ?", params[:brand_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].blank? && params[:goods_type_id].present? && params[:model_id].blank?      
#        products = products.where(["goods_type_id = ? AND products.id NOT IN (?)", params[:goods_type_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["goods_type_id = ?", params[:goods_type_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].blank? && params[:goods_type_id].blank? && params[:model_id].present?      
#        products = products.where(["model_id = ? AND products.id NOT IN (?)", params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["model_id = ?", params[:model_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].present? && params[:goods_type_id].present? && params[:model_id].blank?      
#        products = products.where(["brand_id = ? AND goods_type_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:goods_type_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["brand_id = ? AND goods_type_id = ?", params[:brand_id], params[:goods_type_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].present? && params[:goods_type_id].blank? && params[:model_id].present?      
#        products = products.where(["brand_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["brand_id = ? AND model_id = ?", params[:brand_id], params[:model_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].blank? && params[:goods_type_id].present? && params[:model_id].present?      
#        products = products.where(["goods_type_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:goods_type_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["goods_type_id = ? AND model_id = ?", params[:goods_type_id], params[:model_id]]) if params[:selected_product_ids].blank?
#      elsif params[:brand_id].present? && params[:goods_type_id].present? && params[:model_id].present?      
#        products = products.where(["brand_id = ? AND goods_type_id = ? AND model_id = ? AND products.id NOT IN (?)", params[:brand_id], params[:goods_type_id], params[:model_id], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#        products = products.where(["brand_id = ? AND goods_type_id = ? AND model_id = ?", params[:brand_id], params[:goods_type_id], params[:model_id]]) if params[:selected_product_ids].blank?
#      end
#    else
#      products = Product.joins(:brand).
#        select("products.id, products.code AS product_code, common_fields.name AS product_name").
#        where(["products.code = ?", params[:product_code]]) if params[:selected_product_ids].blank?
#      products = Product.joins(:brand).
#        select("products.id, products.code AS product_code, common_fields.name AS product_name").
#        where(["products.code = ? AND products.id NOT IN (?)", params[:product_code], params[:selected_product_ids].split(",")]) if params[:selected_product_ids].present?
#    end
#    if products.blank?
#      render js: "bootbox.alert({message: \"No records found or already added to the list\",size: 'small'});"
#    else
#      @products = products
#      @counter_event = if params[:counter_event_id].blank?
#        CounterEvent.new
#      else
#        CounterEvent.where(id: params[:counter_event_id]).select(:id).first
#      end
#      @existing_counter_event_new_general_products = []
#      products.each do |product|
#        @existing_counter_event_new_general_products << @counter_event.counter_event_general_products.build(product_id: product.id, prdct_code: product.product_code, prdct_name: product.product_name) if (!@counter_event.new_record? && @counter_event.counter_event_general_products.where(product_id: product.id).select("1 AS one").blank?) || @counter_event.new_record?
#      end
#    end
#  end
#  
#  def generate_activation_form
#  end
#  
#  def activate_deactivate
#    params[:counter_event][:is_active] = nil if params[:counter_event][:is_active].eql?("on")
#    unless @updated = @counter_event.update(counter_event_params)    
#      if @counter_event.errors[:base].present?
#        render js: "bootbox.alert({message: \"#{@counter_event.errors[:base].join("<br/>")}\",size: 'small'});"
#      elsif @counter_event.errors[:"counter_event_warehouses.base"].present?
#        render js: "bootbox.alert({message: \"#{@counter_event.errors[:"counter_event_warehouses.base"].join("<br/>")}\",size: 'small'});"
#      end
#    end
#  end
#
#  private
#  # Use callbacks to share common setup or constraints between actions.
#  def set_counter_event
#    @counter_event = CounterEvent.find(params[:id])
#  end
#
#  # Never trust parameters from the scary internet, only allow the white list through.
#  def counter_event_params
#    params.require(:counter_event).permit(:is_active, :counter_event_activation, :minimum_purchase_amount, :discount_amount, :code, :name, :start_date_time, :end_date_time, :first_plus_discount, :second_plus_discount, :counter_event_type, :cash_discount, :special_price,
#      counter_event_general_products_attributes: [:id, :_destroy, :product_id, :prdct_code, :prdct_name],
#      counter_event_warehouses_attributes: [:is_active, :_destroy, :id, :counter_event_type, :warehouse_id,
#        :wrhs_code, :wrhs_name, :select_different_products,
#        counter_event_products_attributes: [:id, :product_id, :prdct_code, :prdct_name, :_destroy]])
#  end
#  
#  def convert_amount_fields_to_numeric
#    params[:counter_event][:minimum_purchase_amount] = params[:counter_event][:minimum_purchase_amount].gsub("Rp","").gsub(".","").gsub(",",".") if params[:counter_event][:minimum_purchase_amount].present?
#    params[:counter_event][:discount_amount] = params[:counter_event][:discount_amount].gsub("Rp","").gsub(".","").gsub(",",".") if params[:counter_event][:discount_amount].present?
#  end
#
#  def remove_warehouse_products
#    params[:counter_event][:counter_event_warehouses_attributes].each do |key, value|
#      if params[:counter_event][:counter_event_warehouses_attributes][key][:select_different_products].eql?("0")
#        params[:counter_event][:counter_event_warehouses_attributes][key][:counter_event_products_attributes].each do |ep_key, ep_value|
#          if params[:counter_event][:counter_event_warehouses_attributes][key][:counter_event_products_attributes][ep_key][:id].present?
#            params[:counter_event][:counter_event_warehouses_attributes][key][:counter_event_products_attributes][ep_key][:_destroy] = "true"
#          else
#            params[:counter_event][:counter_event_warehouses_attributes][key][:counter_event_products_attributes].delete ep_key
#          end
#        end if params[:counter_event][:counter_event_warehouses_attributes][key][:counter_event_products_attributes].present?
#      end
#    end if params[:counter_event][:counter_event_warehouses_attributes].present?
#  end
#end
