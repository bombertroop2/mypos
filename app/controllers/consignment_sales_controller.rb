include SmartListing::Helper::ControllerExtensions
class ConsignmentSalesController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_consignment_sale, only: [:edit, :update, :destroy, :approve, :unapprove]

  # GET /consignment_sales
  # GET /consignment_sales.json
  def index
    if current_user.has_non_spg_role? && !request.xhr?
      unless current_user.has_role?(:area_manager)
        @counters = Warehouse.counter.actived.select(:id, :code, :name)
      else
        @counters = current_user.supervisor.warehouses.actived.select(:id, :code, :name)
      end
    end
    
    like_command = "ILIKE"
    
    if params[:filter_date].present?
      splitted_start_time_range = params[:filter_date].split("-")
      start_start_time = Date.parse splitted_start_time_range[0].strip
      end_start_time = Date.parse splitted_start_time_range[1].strip
    end
    
    consignment_sales_scope = unless current_user.has_non_spg_role?
      ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved, :no_sale).where(["consignment_sales.warehouse_id = ?", current_user.sales_promotion_girl.warehouse_id])
    else
      if params[:filter_counter_warehouse].blank?
        unless current_user.has_role?(:area_manager)
          ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved, :no_sale)
        else
          warehouse_ids = unless request.xhr?
            @counters.pluck(:id)
          else
            current_user.supervisor.warehouses.pluck(:id)
          end
          ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved, :no_sale).where(["consignment_sales.warehouse_id IN (?)", warehouse_ids])
        end
      else
        ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved, :no_sale).where(["consignment_sales.warehouse_id = ?", params[:filter_counter_warehouse]])
      end
    end
    consignment_sales_scope = consignment_sales_scope.where(["transaction_number #{like_command} ?", "%"+params[:filter_string]+"%"]) if params[:filter_string].present?
    consignment_sales_scope = consignment_sales_scope.where(["transaction_date BETWEEN ? AND ?", start_start_time, end_start_time]) if params[:filter_date].present?
    smart_listing_create(:consignment_sales, consignment_sales_scope, partial: 'consignment_sales/listing', default_sort: {transaction_number: "asc"})
  end

  # GET /consignment_sales/1
  # GET /consignment_sales/1.json
  def show
    @consignment_sale = ConsignmentSale.
      select(:id, :transaction_date, :transaction_number, :total, "warehouses.code, warehouses.name").
      select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
      joins(:warehouse).
      joins("LEFT JOIN counter_events ON consignment_sales.counter_event_id = counter_events.id").
      find(params[:id])
  end

  # GET /consignment_sales/new
  def new
    @consignment_sale = ConsignmentSale.new
    @counters = if current_user.has_role?(:area_manager)
      current_user.supervisor.warehouses.counter.actived.select(:id, :code, :name)
    elsif current_user.has_non_spg_role?
      Warehouse.select(:id, :code, :name).counter.actived
    end
  end

  # GET /consignment_sales/1/edit
  def edit
  end

  # POST /consignment_sales
  # POST /consignment_sales.json
  def create
    add_additional_params_to_consignment_sales    
    calculate_total unless params[:consignment_sale][:no_sale].eql?("true")
    params[:consignment_sale][:consignment_sale_products_attributes].each do |key, value|
      params[:consignment_sale][:consignment_sale_products_attributes][key].merge! attr_no_sale: params[:consignment_sale][:no_sale]
    end if params[:consignment_sale][:consignment_sale_products_attributes].present?
    @consignment_sale = ConsignmentSale.new(consignment_sale_params)
    if params[:consignment_sale][:no_sale].eql?("true") || !current_user.has_non_spg_role?
      @consignment_sale.warehouse_id = @warehouse_id
    end
    unless current_user.has_role?(:area_manager)
      @consignment_sale.attr_create_by_am = false
    else
      @consignment_sale.attr_create_by_am = true      
      @consignment_sale.attr_supervisor_id = current_user.supervisor_id
    end
    
    recreate = false
    recreate_counter = 1

    begin
      begin
        recreate = false
        unless @consignment_sale.save
          if @consignment_sale.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@consignment_sale.errors[:base].join("<br/>")}\",size: 'small'});"
          elsif @consignment_sale.errors[:"consignment_sale_products.base"].present?
            render js: "bootbox.alert({message: \"#{@consignment_sale.errors[:"consignment_sale_products.base"].join("<br/>")}\",size: 'small'});"
          end
        end
      rescue ActiveRecord::RecordNotUnique => e
        if recreate_counter < 5
          recreate = true
          recreate_counter += 1
        else
          recreate = false
          render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
        end
      rescue RuntimeError => e
        recreate = false
        render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
      end
    end while recreate
  end

  # PATCH/PUT /consignment_sales/1
  # PATCH/PUT /consignment_sales/1.json
  def update
    calculate_total_update
    unless @product_selected
      render js: "bootbox.alert({message: \"Please select product(s) that you want to delete\", size: 'small'});"
    else
      if @all_products_deleted
        render js: "bootbox.alert({message: \"Sorry, you can't delete all products\", size: 'small'});"
      else
        @consignment_sale.attr_delete_products = true
        unless current_user.has_non_spg_role?
          warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
          @consignment_sale.attr_spg_warehouse_id = warehouse_id
          params[:consignment_sale][:consignment_sale_products_attributes].each do |key, value|
            if params[:consignment_sale][:consignment_sale_products_attributes][key][:_destroy].eql?("1")
              params[:consignment_sale][:consignment_sale_products_attributes][key].merge! attr_warehouse_id: warehouse_id, attr_delete_products: true
            end
          end
        else
          if current_user.has_role?(:area_manager)
            warehouse_ids = current_user.supervisor.warehouses.pluck(:id)
            @consignment_sale.attr_am_warehouse_ids = warehouse_ids
            params[:consignment_sale][:consignment_sale_products_attributes].each do |key, value|
              if params[:consignment_sale][:consignment_sale_products_attributes][key][:_destroy].eql?("1")
                params[:consignment_sale][:consignment_sale_products_attributes][key].merge! attr_delete_by_am: true, attr_delete_products: true
              end
            end
          else
            params[:consignment_sale][:consignment_sale_products_attributes].each do |key, value|
              if params[:consignment_sale][:consignment_sale_products_attributes][key][:_destroy].eql?("1")
                params[:consignment_sale][:consignment_sale_products_attributes][key].merge! attr_delete_by_admin: true, attr_delete_products: true
              end
            end
          end
        end
        begin
          unless @consignment_sale.update(consignment_sale_params)
            if @consignment_sale.errors[:base].present?
              render js: "bootbox.alert({message: \"#{@consignment_sale.errors[:base].join("<br/>")}\",size: 'small'});"
            end
          end
        rescue RuntimeError => e
          render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
        end
      end
    end
  end

  # DELETE /consignment_sales/1
  # DELETE /consignment_sales/1.json
  def destroy
    begin
      unless current_user.has_non_spg_role?
        warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
        @consignment_sale.attr_spg_warehouse_id = warehouse_id
        @consignment_sale.consignment_sale_products.each do |consignment_sale_product|
          consignment_sale_product.attr_warehouse_id = warehouse_id
        end
      else
        unless current_user.has_role?(:area_manager)
          @consignment_sale.attr_delete_by_admin = true        
          @consignment_sale.consignment_sale_products.each do |consignment_sale_product|
            consignment_sale_product.attr_delete_by_admin = true
          end
        else
          warehouse_ids = current_user.supervisor.warehouses.pluck(:id)
          @consignment_sale.attr_am_warehouse_ids = warehouse_ids
          @consignment_sale.consignment_sale_products.each do |consignment_sale_product|
            consignment_sale_product.attr_delete_by_am = true
          end
        end
      end    
      @consignment_sale.destroy
    rescue RuntimeError => e
      render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
    end
  end
  
  def get_product
    @product = if params[:barcode]
      unless current_user.has_non_spg_role?
        if params[:counter_event_id].blank?
          ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).
            where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, barcode: params[:barcode]).
            where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
            where(["effective_date <= ?", params[:transaction_date].to_date]).
            select(:id, :barcode).
            select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
            select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
            order("effective_date DESC").
            first
        else
          ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [:sales_promotion_girls, counter_event_warehouses: :counter_event]]]]]).
            where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, barcode: params[:barcode]).
            where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
            where(["effective_date <= ?", params[:transaction_date].to_date]).
            where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, params[:counter_event_id], true, true]).
            select(:id, :barcode).
            select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
            select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
            select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
            order("effective_date DESC").
            first
        end
      else
        if current_user.has_role?(:area_manager)
          if params[:counter_event_id].blank?
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: :warehouse]]]).
              where(barcode: params[:barcode]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
              where(["effective_date <= ?", params[:transaction_date].to_date]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%' AND warehouses.supervisor_id = ?", params[:warehouse_id], current_user.supervisor_id]).
              select(:id, :barcode).
              select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(barcode: params[:barcode]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
              where(["effective_date <= ?", params[:transaction_date].to_date]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%' AND warehouses.supervisor_id = ?", params[:warehouse_id], current_user.supervisor_id]).
              where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, params[:counter_event_id], true, true]).
              select(:id, :barcode).
              select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
              select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
              order("effective_date DESC").
              first
          end
        else
          if params[:counter_event_id].blank?
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: :warehouse]]]).
              where(barcode: params[:barcode]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
              where(["effective_date <= ?", params[:transaction_date].to_date]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%'", params[:warehouse_id]]).
              select(:id, :barcode).
              select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(barcode: params[:barcode]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
              where(["effective_date <= ?", params[:transaction_date].to_date]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%'", params[:warehouse_id]]).
              where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, params[:counter_event_id], true, true]).
              select(:id, :barcode).
              select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
              select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
              order("effective_date DESC").
              first
          end
        end
      end
    else
      unless current_user.has_non_spg_role?
        if params[:counter_event_id].blank?
          ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).
            where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, size_id: params[:product_size]).
            where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
            where(["effective_date <= ?", params[:transaction_date].to_date]).
            where(["product_colors.color_id = ? AND products.code = ?", params[:product_color], params[:product_code].upcase]).
            select(:id, :barcode).
            select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
            select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
            order("effective_date DESC").
            first
        else
          ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [:sales_promotion_girls, counter_event_warehouses: :counter_event]]]]]).
            where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, size_id: params[:product_size]).
            where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
            where(["effective_date <= ?", params[:transaction_date].to_date]).
            where(["product_colors.color_id = ? AND products.code = ?", params[:product_color], params[:product_code].upcase]).
            where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, params[:counter_event_id], true, true]).
            select(:id, :barcode).
            select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
            select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
            select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
            order("effective_date DESC").
            first
        end
      else
        if current_user.has_role?(:area_manager)
          if params[:counter_event_id].blank?
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: :warehouse]]]).
              where(:"warehouses.id" => params[:warehouse_id], size_id: params[:product_size]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id AND warehouses.warehouse_type LIKE 'ctr%'").
              where(["effective_date <= ? AND warehouses.supervisor_id = ?", params[:transaction_date].to_date, current_user.supervisor_id]).
              where(["product_colors.color_id = ? AND products.code = ?", params[:product_color], params[:product_code].upcase]).
              select(:id, :barcode).
              select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(:"warehouses.id" => params[:warehouse_id], size_id: params[:product_size]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id AND warehouses.warehouse_type LIKE 'ctr%'").
              where(["effective_date <= ? AND warehouses.supervisor_id = ?", params[:transaction_date].to_date, current_user.supervisor_id]).
              where(["product_colors.color_id = ? AND products.code = ?", params[:product_color], params[:product_code].upcase]).
              where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, params[:counter_event_id], true, true]).
              select(:id, :barcode).
              select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
              select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
              order("effective_date DESC").
              first
          end
        else
          if params[:counter_event_id].blank?
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: :warehouse]]]).
              where(:"warehouses.id" => params[:warehouse_id], size_id: params[:product_size]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id AND warehouses.warehouse_type LIKE 'ctr%'").
              where(["effective_date <= ?", params[:transaction_date].to_date]).
              where(["product_colors.color_id = ? AND products.code = ?", params[:product_color], params[:product_code].upcase]).
              select(:id, :barcode).
              select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(:"warehouses.id" => params[:warehouse_id], size_id: params[:product_size]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id AND warehouses.warehouse_type LIKE 'ctr%'").
              where(["effective_date <= ?", params[:transaction_date].to_date]).
              where(["product_colors.color_id = ? AND products.code = ?", params[:product_color], params[:product_code].upcase]).
              where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, params[:counter_event_id], true, true]).
              select(:id, :barcode).
              select("stock_details.size_id AS product_size_id, stock_details.color_id AS product_color_id, warehouses.id AS warehouse_id").
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stock_details.quantity, stock_details.unapproved_quantity").
              select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
              order("effective_date DESC").
              first
          end
        end
      end
    end
    if @product.present?
      consignment_sale = ConsignmentSale.new
      @consignment_sale_product = consignment_sale.consignment_sale_products.build product_barcode_id: @product.id, price_list_id: @product.price_list_id
    end
  end
  
  def get_product_colors
    @product_colors = unless current_user.has_non_spg_role?
      Color.joins(product_colors: [product: [stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).
        select(:id, :code, :name).
        where(["products.code = ?", params[:product_code].upcase]).
        where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).
        where("stock_details.color_id = common_fields.id").
        distinct
    else
      if current_user.has_role?(:area_manager)
        Color.joins(product_colors: [product: [stock_products: [:stock_details, stock: :warehouse]]]).
          select(:id, :code, :name).
          where(["products.code = ? AND warehouses.supervisor_id = ?", params[:product_code].upcase, current_user.supervisor_id]).
          where(:"warehouses.id" => params[:warehouse_id]).
          where("stock_details.color_id = common_fields.id AND warehouses.warehouse_type LIKE 'ctr%'").
          distinct
      else
        Color.joins(product_colors: [product: [stock_products: [:stock_details, stock: :warehouse]]]).
          select(:id, :code, :name).
          where(["products.code = ?", params[:product_code].upcase]).
          where(:"warehouses.id" => params[:warehouse_id]).
          where("stock_details.color_id = common_fields.id AND warehouses.warehouse_type LIKE 'ctr%'").
          distinct
      end
    end
  end

  def get_product_sizes
    @product_sizes = unless current_user.has_non_spg_role?
      Size.joins(size_group: [products: [:product_colors, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).
        select(:id, :size).
        where(["products.code = ? AND product_colors.color_id = ?", params[:product_code].upcase, params[:product_color]]).
        where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).
        where("stock_details.color_id = product_colors.color_id AND stock_details.size_id = sizes.id").
        order(:size_order)
    else
      if current_user.has_role?(:area_manager)
        Size.joins(size_group: [products: [:product_colors, stock_products: [:stock_details, stock: :warehouse]]]).
          select(:id, :size).
          where(["products.code = ? AND product_colors.color_id = ? AND warehouses.supervisor_id = ?", params[:product_code].upcase, params[:product_color], current_user.supervisor_id]).
          where(:"warehouses.id" => params[:warehouse_id]).
          where("stock_details.color_id = product_colors.color_id AND stock_details.size_id = sizes.id AND warehouses.warehouse_type LIKE 'ctr%'").
          order(:size_order)
      else
        Size.joins(size_group: [products: [:product_colors, stock_products: [:stock_details, stock: :warehouse]]]).
          select(:id, :size).
          where(["products.code = ? AND product_colors.color_id = ?", params[:product_code].upcase, params[:product_color]]).
          where(:"warehouses.id" => params[:warehouse_id]).
          where("stock_details.color_id = product_colors.color_id AND stock_details.size_id = sizes.id AND warehouses.warehouse_type LIKE 'ctr%'").
          order(:size_order)
      end
    end
  end
  
  def approve
    if current_user.has_role?(:area_manager)
      @consignment_sale.attr_supervisor_id = current_user.supervisor_id
    else
      @consignment_sale.attr_spg_warehouse_id = current_user.sales_promotion_girl.warehouse_id
    end
    begin
      unless @consignment_sale.update(approved: true)
        render js: "bootbox.alert({message: \"#{@consignment_sale.errors[:base].join("<br/>")}\",size: 'small'});"
      end
    rescue RuntimeError => e
      render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
    end
  end

  def unapprove
    if current_user.has_role?(:area_manager)
      @consignment_sale.attr_supervisor_id = current_user.supervisor_id
    else
      @consignment_sale.attr_spg_warehouse_id = current_user.sales_promotion_girl.warehouse_id
    end
    begin
      unless @consignment_sale.update(approved: false)
        render js: "bootbox.alert({message: \"#{@consignment_sale.errors[:base].join("<br/>")}\",size: 'small'});"
      end
    rescue RuntimeError => e
      render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
    end
  end
  
  def get_events
    @consignment_sale = ConsignmentSale.new
    @events = if current_user.has_non_spg_role?
      CounterEvent.select(:id, :code, :name).joins(:counter_event_warehouses).where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_event_warehouses.warehouse_id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, params[:warehouse_id], true, true])
    else
      CounterEvent.select(:id, :code, :name).joins(:counter_event_warehouses).where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_event_warehouses.warehouse_id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, current_user.sales_promotion_girl.warehouse_id, true, true])
    end      
  end
  
  private
  
  def calculate_total_update
    total = 0
    @product_selected = false
    @all_products_deleted = true
    params[:consignment_sale][:consignment_sale_products_attributes].each do |key, value|
      if params[:consignment_sale][:consignment_sale_products_attributes][key][:_destroy].eql?("1")
        params[:consignment_sale][:consignment_sale_products_attributes][key].merge! attr_parent_id: @consignment_sale.id
        @product_selected = true
      else
        @all_products_deleted = false
        consignment_sale_product = ConsignmentSaleProduct.select("price_lists.price").joins(:price_list).where(id: params[:consignment_sale][:consignment_sale_products_attributes][key][:id]).first
        subtotal = if @consignment_sale.counter_event_id.present?
          counter_event = CounterEvent.select(:first_discount, :second_discount, :special_price, :counter_event_type).where(id: @consignment_sale.counter_event_id).first
          if counter_event.counter_event_type.eql?("Discount(%)") && counter_event.first_discount.present? && counter_event.second_discount.present?
            first_discounted_subtotal = consignment_sale_product.price - consignment_sale_product.price * counter_event.first_discount / 100
            first_discounted_subtotal - first_discounted_subtotal * counter_event.second_discount / 100
          elsif counter_event.counter_event_type.eql?("Discount(%)") && counter_event.first_discount.present?
            consignment_sale_product.price - consignment_sale_product.price * counter_event.first_discount / 100
          elsif counter_event.counter_event_type.eql?("Special Price") && counter_event.special_price.present?
            counter_event.special_price
          end
        else
          consignment_sale_product.price
        end
        total += subtotal
      end
    end
    @consignment_sale.total = total
  end

  def calculate_total
    total = 0
    params[:consignment_sale][:consignment_sale_products_attributes].each do |key, value|
      product = unless current_user.has_non_spg_role?
        if params[:consignment_sale][:counter_event_id].blank?
          ProductBarcode.joins(product_color: [product: [product_details: :price_lists, stock_products: [stock: [warehouse: :sales_promotion_girls]]]]).
            where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, id: params[:consignment_sale][:consignment_sale_products_attributes][key][:product_barcode_id]).
            where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id").
            where(["effective_date <= ?", params[:consignment_sale][:transaction_date].to_date]).
            select(:barcode, "price_lists.price, price_lists.id AS price_list_id").
            order("effective_date DESC").
            first
        else
          ProductBarcode.joins(product_color: [product: [product_details: :price_lists, stock_products: [stock: [warehouse: [:sales_promotion_girls, counter_event_warehouses: :counter_event]]]]]).
            where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, id: params[:consignment_sale][:consignment_sale_products_attributes][key][:product_barcode_id]).
            where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id").
            where(["effective_date <= ?", params[:consignment_sale][:transaction_date].to_date]).
            where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:consignment_sale][:transaction_date].to_date.end_of_day, params[:consignment_sale][:transaction_date].to_date.beginning_of_day, params[:consignment_sale][:counter_event_id], true, true]).
            select(:barcode, "price_lists.price, price_lists.id AS price_list_id").
            select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
            order("effective_date DESC").
            first
        end
      else
        if current_user.has_role?(:area_manager)
          if params[:consignment_sale][:counter_event_id].blank?
            ProductBarcode.joins(product_color: [product: [product_details: :price_lists, stock_products: [stock: :warehouse]]]).
              where(id: params[:consignment_sale][:consignment_sale_products_attributes][key][:product_barcode_id]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id").
              where(["effective_date <= ? AND warehouses.supervisor_id = ?", params[:consignment_sale][:transaction_date].to_date, current_user.supervisor_id]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%'", params[:consignment_sale][:warehouse_id]]).
              select(:barcode, "price_lists.price, price_lists.id AS price_list_id").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(product_color: [product: [product_details: :price_lists, stock_products: [stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(id: params[:consignment_sale][:consignment_sale_products_attributes][key][:product_barcode_id]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id").
              where(["effective_date <= ? AND warehouses.supervisor_id = ?", params[:consignment_sale][:transaction_date].to_date, current_user.supervisor_id]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%'", params[:consignment_sale][:warehouse_id]]).
              where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:consignment_sale][:transaction_date].to_date.end_of_day, params[:consignment_sale][:transaction_date].to_date.beginning_of_day, params[:consignment_sale][:counter_event_id], true, true]).
              select(:barcode, "price_lists.price, price_lists.id AS price_list_id").
              select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
              order("effective_date DESC").
              first
          end
        else
          if params[:consignment_sale][:counter_event_id].blank?
            ProductBarcode.joins(product_color: [product: [product_details: :price_lists, stock_products: [stock: :warehouse]]]).
              where(id: params[:consignment_sale][:consignment_sale_products_attributes][key][:product_barcode_id]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id").
              where(["effective_date <= ?", params[:consignment_sale][:transaction_date].to_date]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%'", params[:consignment_sale][:warehouse_id]]).
              select(:barcode, "price_lists.price, price_lists.id AS price_list_id").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(product_color: [product: [product_details: :price_lists, stock_products: [stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(id: params[:consignment_sale][:consignment_sale_products_attributes][key][:product_barcode_id]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id").
              where(["effective_date <= ?", params[:consignment_sale][:transaction_date].to_date]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%'", params[:consignment_sale][:warehouse_id]]).
              where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:consignment_sale][:transaction_date].to_date.end_of_day, params[:consignment_sale][:transaction_date].to_date.beginning_of_day, params[:consignment_sale][:counter_event_id], true, true]).
              select(:barcode, "price_lists.price, price_lists.id AS price_list_id").
              select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
              order("effective_date DESC").
              first
          end
        end
      end
      subtotal = if params[:consignment_sale][:counter_event_id].present? && product.counter_event_type.present?
        if product.counter_event_type.eql?("Discount(%)") && product.first_discount.present? && product.second_discount.present?
          first_discounted_subtotal = product.price - product.price * product.first_discount / 100
          first_discounted_subtotal - first_discounted_subtotal * product.second_discount / 100
        elsif product.counter_event_type.eql?("Discount(%)") && product.first_discount.present?
          product.price - product.price * product.first_discount / 100
        elsif product.counter_event_type.eql?("Special Price") && product.special_price.present?
          product.special_price
        end
      else
        params[:consignment_sale][:counter_event_id] = nil if params[:consignment_sale][:counter_event_id].present?
        product.price
      end
      params[:consignment_sale][:consignment_sale_products_attributes][key][:price_list_id] = product.price_list_id
      params[:consignment_sale][:consignment_sale_products_attributes][key].merge! total: subtotal, attr_warehouse_id: @warehouse_id, attr_barcode: product.barcode, attr_transaction_date: params[:consignment_sale][:transaction_date]
      total += subtotal
    end if params[:consignment_sale][:consignment_sale_products_attributes].present?
    params[:consignment_sale].merge! total: total
  end
  
  def add_additional_params_to_consignment_sales
    unless current_user.has_non_spg_role?
      spg = SalesPromotionGirl.joins(:warehouse).select(:warehouse_id, "warehouses.code").where(id: current_user.sales_promotion_girl_id).first
      @warehouse_id = spg.warehouse_id
      @warehouse_code = spg.code
    else
      warehouse = if current_user.has_role?(:area_manager)
        Warehouse.select(:id, :code).where(id: params[:consignment_sale][:warehouse_id], supervisor_id: current_user.supervisor_id).first
      else
        Warehouse.select(:id, :code).where(id: params[:consignment_sale][:warehouse_id]).first
      end
      @warehouse_id = warehouse.id
      @warehouse_code = warehouse.code
    end
    params[:consignment_sale].merge! attr_warehouse_code: @warehouse_code
  end
  
  # Use callbacks to share common setup or constraints between actions.
  def set_consignment_sale
    @consignment_sale = ConsignmentSale.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def consignment_sale_params
    unless action_name.eql?("update")
      unless current_user.has_non_spg_role?
        params.require(:consignment_sale).permit(:no_sale, :counter_event_id, :total, :attr_warehouse_code, :transaction_date,
          consignment_sale_products_attributes: [:product_barcode_id, :price_list_id, :total, :attr_warehouse_id, :attr_barcode, :attr_transaction_date, :attr_no_sale])
      else
        params.require(:consignment_sale).permit(:no_sale, :counter_event_id, :total, :attr_warehouse_code, :transaction_date, :warehouse_id,
          consignment_sale_products_attributes: [:product_barcode_id, :price_list_id, :total, :attr_warehouse_id, :attr_barcode, :attr_transaction_date, :attr_no_sale])
      end
    else
      if current_user.has_role?(:area_manager)
        params.require(:consignment_sale).permit(consignment_sale_products_attributes: [:_destroy, :id, :attr_parent_id, :attr_delete_by_am])
      else
        if current_user.has_non_spg_role?
          params.require(:consignment_sale).permit(consignment_sale_products_attributes: [:_destroy, :id, :attr_parent_id, :attr_delete_by_admin])
        else
          params.require(:consignment_sale).permit(consignment_sale_products_attributes: [:_destroy, :id, :attr_parent_id, :attr_warehouse_id])
        end
      end
    end
  end
end
