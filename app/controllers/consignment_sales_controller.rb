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
    
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    
    if params[:filter_date].present?
      splitted_start_time_range = params[:filter_date].split("-")
      start_start_time = Date.parse splitted_start_time_range[0].strip
      end_start_time = Date.parse splitted_start_time_range[1].strip
    end
    
    consignment_sales_scope = unless current_user.has_non_spg_role?
      warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
      user_ids = SalesPromotionGirl.select("users.id AS user_id").joins(:user).where(:"sales_promotion_girls.warehouse_id" => warehouse_id).map(&:user_id).uniq
      ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved).joins(:audits).where(["(audits.user_id IN (?) AND audits.action = 'create') OR consignment_sales.warehouse_id = ?", user_ids, warehouse_id]).distinct
    else
      if params[:filter_counter_warehouse].blank?
        unless current_user.has_role?(:area_manager)
          ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved)
        else
          warehouse_ids = unless request.xhr?
            @counters.pluck(:id)
          else
            current_user.supervisor.warehouses.pluck(:id)
          end
          user_ids = SalesPromotionGirl.select("users.id AS user_id").joins(:user).where(:"sales_promotion_girls.warehouse_id" => warehouse_ids).map(&:user_id).uniq
          ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved).joins(:audits).where(["(audits.user_id IN (?) AND audits.action = 'create') OR consignment_sales.warehouse_id IN (?)", user_ids, warehouse_ids]).distinct
        end
      else
        unless current_user.has_role?(:area_manager)
          user_ids = SalesPromotionGirl.select("users.id AS user_id").joins(:user).where(:"sales_promotion_girls.warehouse_id" => params[:filter_counter_warehouse]).map(&:user_id).uniq
          ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved).joins(:audits).where(["(audits.user_id IN (?) AND audits.action = 'create') OR consignment_sales.warehouse_id = ?", user_ids, params[:filter_counter_warehouse]]).distinct
        else
          user_ids = SalesPromotionGirl.
            select("users.id AS user_id").
            joins(:warehouse).
            joins(:user).
            where(:"sales_promotion_girls.warehouse_id" => params[:filter_counter_warehouse]).
            where(["warehouses.warehouse_type LIKE 'ctr%' AND warehouses.is_active = ? AND warehouses.supervisor_id = ?", true, current_user.supervisor_id]).
            map(&:user_id).
            uniq
          ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved).
            joins("LEFT JOIN warehouses ON consignment_sales.warehouse_id = warehouses.id").
            joins(:audits).where(["(audits.user_id IN (?) AND audits.action = 'create') OR (consignment_sales.warehouse_id = ? AND warehouses.warehouse_type LIKE 'ctr%' AND warehouses.is_active = ?)", user_ids, params[:filter_counter_warehouse], true]).distinct
        end
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
      select("sales_promotion_girls_warehouses.code AS sales_promotion_girls_warehouses_code, sales_promotion_girls_warehouses.name AS sales_promotion_girls_warehouses_name").
      joins(:audits).
      joins("LEFT JOIN counter_events ON consignment_sales.counter_event_id = counter_events.id").
      joins("LEFT JOIN warehouses ON consignment_sales.warehouse_id = warehouses.id").
      joins("LEFT JOIN users ON audits.user_id = users.id AND audits.user_type = 'User'").
      joins("LEFT JOIN sales_promotion_girls ON users.sales_promotion_girl_id = sales_promotion_girls.id").
      joins("LEFT JOIN warehouses sales_promotion_girls_warehouses ON sales_promotion_girls.warehouse_id = sales_promotion_girls_warehouses.id").
      where("audits.action = 'create'").
      find(params[:id])
  end

  # GET /consignment_sales/new
  def new
    @consignment_sale = ConsignmentSale.new
    @counters = if current_user.has_role?(:area_manager)
      current_user.supervisor.warehouses.counter.select(:id, :code, :name)
    elsif current_user.has_non_spg_role?
      Warehouse.select(:id, :code, :name).counter
    end
  end

  # GET /consignment_sales/1/edit
  def edit
  end

  # POST /consignment_sales
  # POST /consignment_sales.json
  def create
    add_additional_params_to_consignment_sales
    calculate_total
    @consignment_sale = ConsignmentSale.new(consignment_sale_params)
    @consignment_sale.attr_create_by_admin = unless current_user.has_non_spg_role?
      false
    else
      true
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
    respond_to do |format|
      if @consignment_sale.update(consignment_sale_params)
        format.html { redirect_to @consignment_sale, notice: 'Consignment sale was successfully updated.' }
        format.json { render :show, status: :ok, location: @consignment_sale }
      else
        format.html { render :edit }
        format.json { render json: @consignment_sale.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /consignment_sales/1
  # DELETE /consignment_sales/1.json
  def destroy
    begin
      unless current_user.has_non_spg_role?
        warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
        if @consignment_sale.warehouse_id.blank?
          user_ids = SalesPromotionGirl.select("users.id AS user_id").joins(:user).where(:"sales_promotion_girls.warehouse_id" => warehouse_id).map(&:user_id).uniq
          @consignment_sale.attr_user_ids = user_ids
        else
          @consignment_sale.attr_spg_warehouse_id = warehouse_id
        end
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
          if @consignment_sale.warehouse_id.blank?
            user_ids = SalesPromotionGirl.select("users.id AS user_id").joins(:user).where(:"sales_promotion_girls.warehouse_id" => warehouse_ids).map(&:user_id).uniq
            @consignment_sale.attr_user_ids = user_ids
          else
            @consignment_sale.attr_am_warehouse_ids = warehouse_ids
          end
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
            select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
            order("effective_date DESC").
            first
        else
          ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [:sales_promotion_girls, counter_event_warehouses: :counter_event]]]]]).
            where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, barcode: params[:barcode]).
            where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
            where(["effective_date <= ?", params[:transaction_date].to_date]).
            where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, params[:counter_event_id], true, true]).
            select(:id, :barcode).
            select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
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
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(barcode: params[:barcode]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
              where(["effective_date <= ?", params[:transaction_date].to_date]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%' AND warehouses.supervisor_id = ?", params[:warehouse_id], current_user.supervisor_id]).
              where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, params[:counter_event_id], true, true]).
              select(:id, :barcode).
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
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
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(barcode: params[:barcode]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
              where(["effective_date <= ?", params[:transaction_date].to_date]).
              where(["warehouses.id = ? AND warehouses.warehouse_type LIKE 'ctr%'", params[:warehouse_id]]).
              where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, params[:counter_event_id], true, true]).
              select(:id, :barcode).
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
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
            select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
            order("effective_date DESC").
            first
        else
          ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [:sales_promotion_girls, counter_event_warehouses: :counter_event]]]]]).
            where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, size_id: params[:product_size]).
            where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
            where(["effective_date <= ?", params[:transaction_date].to_date]).
            where(["product_colors.color_id = ? AND products.code = ?", params[:product_color], params[:product_code].upcase]).
            where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, params[:counter_event_id], true, true]).
            select(:id, :barcode).
            select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
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
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(:"warehouses.id" => params[:warehouse_id], size_id: params[:product_size]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id AND warehouses.warehouse_type LIKE 'ctr%'").
              where(["effective_date <= ? AND warehouses.supervisor_id = ?", params[:transaction_date].to_date, current_user.supervisor_id]).
              where(["product_colors.color_id = ? AND products.code = ?", params[:product_color], params[:product_code].upcase]).
              where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, params[:counter_event_id], true, true]).
              select(:id, :barcode).
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
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
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
              order("effective_date DESC").
              first
          else
            ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: [counter_event_warehouses: :counter_event]]]]]).
              where(:"warehouses.id" => params[:warehouse_id], size_id: params[:product_size]).
              where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id AND warehouses.warehouse_type LIKE 'ctr%'").
              where(["effective_date <= ?", params[:transaction_date].to_date]).
              where(["product_colors.color_id = ? AND products.code = ?", params[:product_color], params[:product_code].upcase]).
              where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, params[:counter_event_id], true, true]).
              select(:id, :barcode).
              select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").
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
    @consignment_sale.attr_supervisor_id = current_user.supervisor_id if current_user.has_role?(:area_manager)
    begin
      unless @consignment_sale.update(approved: true)
        render js: "bootbox.alert({message: \"#{@consignment_sale.errors[:base].join("<br/>")}\",size: 'small'});"
      end
    rescue RuntimeError => e
      render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
    end
  end

  def unapprove
    @consignment_sale.attr_supervisor_id = current_user.supervisor_id if current_user.has_role?(:area_manager)
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
      CounterEvent.select(:id, :code, :name).joins(:counter_event_warehouses).where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_event_warehouses.warehouse_id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, params[:warehouse_id], true, true])
    else
      CounterEvent.select(:id, :code, :name).joins(:counter_event_warehouses).where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_event_warehouses.warehouse_id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, current_user.sales_promotion_girl.warehouse_id, true, true])
    end      
  end

  private
  
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
            where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:consignment_sale][:transaction_date].to_date, params[:consignment_sale][:transaction_date].to_date, params[:consignment_sale][:counter_event_id], true, true]).
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
              where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:consignment_sale][:transaction_date].to_date, params[:consignment_sale][:transaction_date].to_date, params[:consignment_sale][:counter_event_id], true, true]).
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
              where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:consignment_sale][:transaction_date].to_date, params[:consignment_sale][:transaction_date].to_date, params[:consignment_sale][:counter_event_id], true, true]).
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
      params[:consignment_sale][:consignment_sale_products_attributes][key].merge! total: subtotal, attr_warehouse_id: @warehouse_id, attr_barcode: product.barcode
      total += subtotal
    end if params[:consignment_sale][:consignment_sale_products_attributes].present?
    params[:consignment_sale].merge! total: total
  end
  
  def add_additional_params_to_consignment_sales
    unless current_user.has_non_spg_role?
      spg = SalesPromotionGirl.joins(:warehouse).select(:warehouse_id, "warehouses.code").where(id: current_user.sales_promotion_girl_id).first
      @warehouse_id = spg.warehouse_id
      warehouse_code = spg.code
    else
      warehouse = if current_user.has_role?(:area_manager)
        Warehouse.select(:id, :code).where(id: params[:consignment_sale][:warehouse_id], supervisor_id: current_user.supervisor_id).first
      else
        Warehouse.select(:id, :code).where(id: params[:consignment_sale][:warehouse_id]).first
      end
      @warehouse_id = warehouse.id
      warehouse_code = warehouse.code
    end
    params[:consignment_sale].merge! attr_warehouse_code: warehouse_code
  end
  
  # Use callbacks to share common setup or constraints between actions.
  def set_consignment_sale
    @consignment_sale = ConsignmentSale.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def consignment_sale_params
    unless current_user.has_non_spg_role?
      params.require(:consignment_sale).permit(:counter_event_id, :total, :attr_warehouse_code, :transaction_date, consignment_sale_products_attributes: [:product_barcode_id, :price_list_id, :total, :attr_warehouse_id, :attr_barcode])
    else
      params.require(:consignment_sale).permit(:counter_event_id, :total, :attr_warehouse_code, :transaction_date, :warehouse_id, consignment_sale_products_attributes: [:product_barcode_id, :price_list_id, :total, :attr_warehouse_id, :attr_barcode])
    end
  end
end
