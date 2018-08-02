include SmartListing::Helper::ControllerExtensions
class SalesController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_sale, only: [:show, :edit, :update, :destroy]
  #  skip_before_action :verify_authenticity_token, only: :print

  # GET /sales
  # GET /sales.json
  def index
    like_command = "ILIKE"
    
    if params[:filter_date].present?
      splitted_start_time_range = params[:filter_date].split("-")
      #      start_start_time = Time.zone.parse splitted_start_time_range[0].strip
      #      end_start_time = Time.zone.parse splitted_start_time_range[1].strip
      start_start_time = Time.zone.parse(splitted_start_time_range[0].strip)
      end_start_time = Time.zone.parse(splitted_start_time_range[1].strip).end_of_day
    end

    warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
    sales_scope = Sale.joins(:cashier_opening).select(:id, :transaction_time, :total, :transaction_number, :payment_method, :sales_return_id).where("opened_by = #{current_user.id} AND warehouse_id = #{warehouse_id}")
    sales_scope = sales_scope.where(["transaction_time BETWEEN ? AND ?", start_start_time, end_start_time]) if params[:filter_date].present?
    sales_scope = sales_scope.where(["transaction_number #{like_command} ?", "%"+params[:filter_string]+"%"]) if params[:filter_string].present?
    sales_scope = sales_scope.where(["payment_method = ?", params[:filter_payment_method]]) if params[:filter_payment_method].present?
    @sales = smart_listing_create(:sales, sales_scope, partial: 'sales/listing', default_sort: {transaction_time: "DESC"})
  end

  # GET /sales/1
  # GET /sales/1.json
  def show
  end

  def print
    @sale = Sale.joins(cashier_opening: [warehouse: :sales_promotion_girls]).
      joins("LEFT JOIN members on members.id = sales.member_id").
      joins("LEFT JOIN banks on banks.id = sales.bank_id").
      joins("LEFT JOIN stock_details on sales.gift_event_product_id = stock_details.id").
      joins("LEFT JOIN stock_products on stock_details.stock_product_id = stock_products.id").
      joins("LEFT JOIN products on stock_products.product_id = products.id").
      joins("LEFT JOIN sizes ON stock_details.size_id = sizes.id").
      joins("LEFT JOIN common_fields colors_products ON colors_products.id = stock_details.color_id AND colors_products.type IN ('Color')").
      joins("LEFT JOIN events ON events.id = sales.gift_event_id").
      select(:id, :sales_return_id, "warehouses.name AS warehouse_name, warehouses.address AS warehouse_address, sales.bank_id, sales.gift_event_id, sales.member_id, members.member_id AS member_identifier, members.name AS member_name, sales.transaction_time, sales.payment_method, sales.total, sales.cash, sales.change, sales.transaction_number, banks.code AS bank_code, banks.name AS bank_name, banks.card_type, sales.card_number, sales.trace_number, products.code AS product_code, sizes.size AS product_size, colors_products.code AS color_code, colors_products.name AS color_name, events.event_type, events.discount_amount, sales.gift_event_product_id, sales_promotion_girls.identifier AS cashier_identifier, sales_promotion_girls.name AS cashier_name, warehouses.first_message, warehouses.second_message, warehouses.third_message, warehouses.fourth_message, warehouses.fifth_message").
      where(sales_return_id: nil).
      where(id: params[:id]).
      where(["sales_promotion_girls.id = ?", current_user.sales_promotion_girl_id]).first
  end
  
  def print_return_receipt
    @sale = Sale.joins(:returned_document, cashier_opening: [warehouse: :sales_promotion_girls]).
      joins("LEFT JOIN members on members.id = sales.member_id").
      joins("LEFT JOIN banks on banks.id = sales.bank_id").
      select(:id, :gift_event_id, :sales_return_id, "warehouses.name AS warehouse_name, warehouses.address AS warehouse_address, sales.bank_id, sales.member_id, members.member_id AS member_identifier, members.name AS member_name, sales.transaction_time, sales.payment_method, sales.total, sales.cash, sales.change, sales.transaction_number, banks.code AS bank_code, banks.name AS bank_name, banks.card_type, sales.card_number, sales.trace_number, sales_promotion_girls.identifier AS cashier_identifier, sales_promotion_girls.name AS cashier_name, warehouses.first_message, warehouses.second_message, warehouses.third_message, warehouses.fourth_message, warehouses.fifth_message, sales_returns.total_return").
      where("sales_return_id IS NOT NULL").
      where(id: params[:id]).
      where(["sales_promotion_girls.id = ?", current_user.sales_promotion_girl_id]).first
  end

  # GET /sales/new
  def new
    session.delete("sale")
    @sale = Sale.new
    warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
    @cashier_opened = CashierOpening.select("1 AS one").where(warehouse_id: warehouse_id).where("closed_at IS NULL").where(["open_date = ?", Date.current]).where("opened_by = #{current_user.id}").present?
  end

  # GET /sales/1/edit
  def edit
  end

  # POST /sales
  # POST /sales.json
  def create
    convert_money_to_numeric
    add_additional_params_to_sale_products
    set_total
    if @total >= @minimum_purchase_amount && params[:sale][:gift_event_gift_type].strip.blank? && session["sale"].present? && session["sale"]["event"].present? && @minimum_purchase_amount > 0
      @generate_add_gift_form = true
    elsif session["sale"].present? && session["sale"]["event"].present? && params[:sale][:gift_event_gift_type].strip.eql?("Discount") && @discount_amount.present? && @discount_amount == 0
      render js: "bootbox.alert({message: \"Sorry, there is no available discount for this transaction yet\",size: 'small'});"
    else
      add_additional_params_to_sale
      if params[:sale][:gift_event_gift_type].strip.eql?("Discount") && @discount_amount.present? && @discount_amount > 0 && @total >= @minimum_purchase_amount && @minimum_purchase_amount > 0
        @total = @total - @discount_amount
      end

      params[:sale].merge! total: @total
      @sale = Sale.new(sale_params)

      recreate = false
      recreate_counter = 1
      begin
        begin
          recreate = false
          unless @valid = @sale.save
            if @sale.errors[:base].present?
              render js: "bootbox.alert({message: \"#{@sale.errors[:base].join("<br/>")}\",size: 'small'});"
            elsif @sale.errors[:"sale_products.base"].present?
              render js: "bootbox.alert({message: \"#{@sale.errors[:"sale_products.base"].join("<br/>")}\",size: 'small'});"
            else
              @member = Member.select(:id, :name, :address, :phone, :mobile_phone, :gender, :email, :member_id).where(id: @sale.member_id).first# if @sale.member_id.present?
            end
          end
        rescue ActiveRecord::RecordNotUnique => e
          if recreate_counter < 3
            recreate = true
            recreate_counter += 1
          else
            recreate = false
            render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
          end
        rescue Exception => e
          recreate = false
          render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
        end
      end while recreate
    end
  end

  # PATCH/PUT /sales/1
  # PATCH/PUT /sales/1.json
  def update
    respond_to do |format|
      if @sale.update(sale_params)
        format.html { redirect_to @sale, notice: 'Sale was successfully updated.' }
        format.json { render :show, status: :ok, location: @sale }
      else
        format.html { render :edit }
        format.json { render json: @sale.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sales/1
  # DELETE /sales/1.json
  def destroy
    @sale.destroy
    respond_to do |format|
      format.html { redirect_to sales_url, notice: 'Sale was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def get_member
    @member = Member.select(:id, :name, :address, :phone, :mobile_phone, :gender, :email, :member_id).where(member_id: params[:member_id]).first
  end

  def get_product
    sale = Sale.new
    @product = if params[:barcode]
      ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, barcode: params[:barcode]).where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").where(["effective_date <= ?", Date.current]).select(:id, :barcode).select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").order("effective_date DESC").first
    else
      ProductBarcode.joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, size_id: params[:sale_product_size]).where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").where(["effective_date <= ?", Date.current]).where(["product_colors.color_id = ? AND products.code = ?", params[:sale_product_color], params[:sale_product_code].upcase]).select(:id, :barcode).select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id").order("effective_date DESC").first
    end
    if @product
      current_time = Time.current
      warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
      
      event_specific_product = Event.joins(event_warehouses: :event_products).select(:created_at, :id, :first_plus_discount, :second_plus_discount, :cash_discount, :special_price, :event_type, :minimum_purchase_amount, :discount_amount).where(["start_date_time <= ? AND end_date_time > ? AND event_warehouses.warehouse_id = ? AND event_products.product_id = ? AND select_different_products = ? AND (events.is_active = ? OR event_warehouses.is_active = ?) AND event_type <> 'Gift'", current_time, current_time, warehouse_id, @product.product_id, true, true, true]).order("events.created_at DESC").first
      event_general_product = Event.joins(:event_warehouses, :event_general_products).select(:created_at, :id, :first_plus_discount, :second_plus_discount, :cash_discount, :special_price, :event_type, :minimum_purchase_amount, :discount_amount).where(["start_date_time <= ? AND end_date_time > ? AND event_warehouses.warehouse_id = ? AND event_general_products.product_id = ? AND (select_different_products = ? OR select_different_products IS NULL) AND (events.is_active = ? OR event_warehouses.is_active = ?) AND event_type <> 'Gift'", current_time, current_time, warehouse_id, @product.product_id, false, true, true]).order("events.created_at DESC").first
      if event_specific_product.nil? && event_general_product.present?
        @store_event = event_general_product
      elsif event_specific_product.present? && event_general_product.nil?
        @store_event = event_specific_product
      elsif event_specific_product.present? && event_general_product.present?
        if event_specific_product.created_at >= event_general_product.created_at
          @store_event = event_specific_product
        else          
          @store_event = event_general_product
        end
      else
        @store_event = nil
      end

      gift_event = Event.joins(:event_warehouses).select(:created_at, :id, :first_plus_discount, :second_plus_discount, :cash_discount, :special_price, :event_type, :minimum_purchase_amount, :discount_amount).where(["start_date_time <= ? AND end_date_time > ? AND event_warehouses.warehouse_id = ? AND (events.is_active = ? OR event_warehouses.is_active = ?) AND event_type = 'Gift'", current_time, current_time, warehouse_id, true, true]).order("events.created_at DESC").first
      if @store_event.present? && gift_event.present? && gift_event.created_at > @store_event.created_at
        @store_event = gift_event
      elsif @store_event.blank? && gift_event.present?
        @store_event = gift_event
      end
      @sale_product = if @store_event.present?
        sale.sale_products.build product_barcode_id: @product.id, quantity: 1, event_id: @store_event.id
      else
        sale.sale_products.build product_barcode_id: @product.id, quantity: 1
      end
    end
  end

  def get_free_product
    @product = if params[:barcode]
      #      StockDetail.joins(:size, stock_product: [product: [:brand, product_colors: [:product_barcodes, :color]], stock: [warehouse: :sales_promotion_girls]]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, :"product_barcodes.barcode" => params[:barcode]).where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").select(:id, "sizes.size AS product_size", "common_fields.name", "colors_product_colors.name AS color_name").first
      StockDetail.joins(:size, stock_product: [product: [:brand, product_details: :price_lists, product_colors: [:product_barcodes, :color]], stock: [warehouse: :sales_promotion_girls]]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, :"product_barcodes.barcode" => params[:barcode]).where(["price_lists.effective_date <= ?", Date.current]).where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id AND product_details.size_id = stock_details.size_id AND product_details.price_code_id = warehouses.price_code_id").select(:id, "sizes.size AS product_size", "common_fields.name AS brand_name", "colors_product_colors.name AS color_name", "product_barcodes.id AS product_barcode_id", "price_lists.price", "product_barcodes.barcode AS product_barcode", "products.code AS product_code", "colors_product_colors.code AS color_code", "price_lists.id AS price_list_id").order("price_lists.effective_date DESC").first
    else
      #      StockDetail.joins(:size, stock_product: [product: [:brand, product_colors: :color], stock: [warehouse: :sales_promotion_girls]]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, :"products.code" => params[:sale_bogo_product_code].upcase, size_id: params[:sale_bogo_product_size], color_id: params[:sale_bogo_product_color]).where("stock_details.color_id = product_colors.color_id").select(:id, "sizes.size AS product_size", "common_fields.name", "colors_product_colors.name AS color_name").first
      StockDetail.joins(:size, stock_product: [product: [:brand, product_details: :price_lists, product_colors: [:product_barcodes, :color]], stock: [warehouse: :sales_promotion_girls]]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, :"products.code" => params[:sale_bogo_product_code].upcase, size_id: params[:sale_bogo_product_size], color_id: params[:sale_bogo_product_color]).where(["price_lists.effective_date <= ?", Date.current]).where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id AND product_details.size_id = stock_details.size_id AND product_details.price_code_id = warehouses.price_code_id").select(:id, "sizes.size AS product_size", "common_fields.name AS brand_name", "colors_product_colors.name AS color_name", "product_barcodes.id AS product_barcode_id", "price_lists.price", "product_barcodes.barcode AS product_barcode", "products.code AS product_code", "colors_product_colors.code AS color_code", "price_lists.id AS price_list_id").order("price_lists.effective_date DESC").first
    end

    #    if @product.present?
    #      session["sale"][params[:product_barcode_id]][params[:product_row_index]] ||= {}
    #      session["sale"][params[:product_barcode_id]][params[:product_row_index]]["free_product_id"] = @product.id
    #      #      session["sale"][params[:product_barcode_id]]["free_product_id"] = @product.id
    #    else
    #      session["sale"][params[:product_barcode_id]].delete(params[:product_row_index]) if session["sale"][params[:product_barcode_id]][params[:product_row_index]].present?
    #    end
  end
  
  def get_product_colors
    @product_colors = Color.joins(product_colors: [product: [stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).select(:id, :code, :name).where(["products.code = ?", params[:sale_product_code].upcase]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).where("stock_details.color_id = common_fields.id").distinct
  end

  def get_free_product_colors
    @product_colors = Color.joins(product_colors: [product: [stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).select(:id, :code, :name).where(["products.code = ?", params[:sale_bogo_product_code].upcase]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).where("stock_details.color_id = common_fields.id").distinct
  end

  def get_product_sizes
    @product_sizes = Size.joins(size_group: [products: [:product_colors, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).select(:id, :size).where(["products.code = ? AND product_colors.color_id = ?", params[:sale_product_code].upcase, params[:sale_product_color]]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).where("stock_details.color_id = product_colors.color_id AND stock_details.size_id = sizes.id").order(:size_order)
  end
  
  def get_free_product_sizes
    @product_sizes = Size.joins(size_group: [products: [:product_colors, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).select(:id, :size).where(["products.code = ? AND product_colors.color_id = ?", params[:sale_bogo_product_code].upcase, params[:sale_bogo_product_color]]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).where("stock_details.color_id = product_colors.color_id AND stock_details.size_id = sizes.id").order(:size_order)    
  end
  
  def get_gift_event_product
    current_time = Time.current
    if params[:barcode]
      @gift_item = StockDetail.joins(:size, stock_product: [product: [:brand, product_colors: [:product_barcodes, :color], event_products: [event_warehouse: :event]], stock: [warehouse: :sales_promotion_girls]]).
        where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, :"product_barcodes.barcode" => params[:barcode]).
        where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
        #        where(["events.start_date_time <= ? AND events.end_date_time > ? AND event_warehouses.warehouse_id = stocks.warehouse_id AND event_warehouses.select_different_products = ? AND (events.is_active = ? OR event_warehouses.is_active = ?) AND events.event_type = 'Gift' AND events.id = ?", current_time, current_time, true, true, true, session["sale"]["event"]["id"]]).
      where(["event_warehouses.warehouse_id = stocks.warehouse_id AND event_warehouses.select_different_products = ? AND (events.is_active = ? OR event_warehouses.is_active = ?) AND events.id = ?", true, true, true, session["sale"]["event"]["id"]]).
        select(:id, "sizes.size AS product_size", "common_fields.name", "colors_product_colors.name AS color_name").
        order("events.created_at DESC").first
      if @gift_item.blank?
        @gift_item = StockDetail.joins(:size, stock_product: [product: [:brand, :event_general_products, product_colors: [:product_barcodes, :color]], stock: [warehouse: [:sales_promotion_girls, event_warehouses: :event]]]).
          where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, :"product_barcodes.barcode" => params[:barcode]).
          where("stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
          #          where(["events.start_date_time <= ? AND events.end_date_time > ? AND event_general_products.event_id = events.id AND (select_different_products = ? OR select_different_products IS NULL) AND (events.is_active = ? OR event_warehouses.is_active = ?) AND events.event_type = 'Gift' AND events.id = ?", current_time, current_time, false, true, true, session["sale"]["event"]["id"]]).
        where(["event_general_products.event_id = events.id AND (select_different_products = ? OR select_different_products IS NULL) AND (events.is_active = ? OR event_warehouses.is_active = ?) AND events.id = ?", false, true, true, session["sale"]["event"]["id"]]).
          select(:id, "sizes.size AS product_size", "common_fields.name", "colors_product_colors.name AS color_name").
          order("events.created_at DESC").first
      end
    elsif params[:product_code] && params[:product_color] && params[:product_size]
      @gift_item = StockDetail.joins(:size, stock_product: [product: [:brand, product_colors: :color, event_products: [event_warehouse: :event]], stock: [warehouse: :sales_promotion_girls]]).
        where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, :"stock_details.size_id" => params[:product_size], :"stock_details.color_id" => params[:product_color], :"products.code" => params[:product_code].upcase).
        where("stock_details.color_id = product_colors.color_id").
        #        where(["events.start_date_time <= ? AND events.end_date_time > ? AND event_warehouses.warehouse_id = stocks.warehouse_id AND event_warehouses.select_different_products = ? AND (events.is_active = ? OR event_warehouses.is_active = ?) AND events.event_type = 'Gift' AND events.id = ?", current_time, current_time, true, true, true, session["sale"]["event"]["id"]]).
      where(["event_warehouses.warehouse_id = stocks.warehouse_id AND event_warehouses.select_different_products = ? AND (events.is_active = ? OR event_warehouses.is_active = ?) AND events.id = ?", true, true, true, session["sale"]["event"]["id"]]).
        select(:id, "sizes.size AS product_size", "common_fields.name", "colors_product_colors.name AS color_name").
        order("events.created_at DESC").first
      if @gift_item.blank?
        @gift_item = StockDetail.joins(:size, stock_product: [product: [:brand, :event_general_products, product_colors: :color], stock: [warehouse: [:sales_promotion_girls, event_warehouses: :event]]]).
          where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, :"stock_details.size_id" => params[:product_size], :"stock_details.color_id" => params[:product_color], :"products.code" => params[:product_code].upcase).
          where("stock_details.color_id = product_colors.color_id").
          #          where(["events.start_date_time <= ? AND events.end_date_time > ? AND event_general_products.event_id = events.id AND (select_different_products = ? OR select_different_products IS NULL) AND (events.is_active = ? OR event_warehouses.is_active = ?) AND events.event_type = 'Gift' AND events.id = ?", current_time, current_time, false, true, true, session["sale"]["event"]["id"]]).
        where(["event_general_products.event_id = events.id AND (select_different_products = ? OR select_different_products IS NULL) AND (events.is_active = ? OR event_warehouses.is_active = ?) AND events.id = ?", false, true, true, session["sale"]["event"]["id"]]).
          select(:id, "sizes.size AS product_size", "common_fields.name", "colors_product_colors.name AS color_name").
          order("events.created_at DESC").first
      end
    end
    
    if @gift_item.present?
      session["sale"]["gift_event_product_id"] = @gift_item.id
      session["sale"]["gift_event_product_detail"] = "#{@gift_item.name}/#{@gift_item.color_name}/#{@gift_item.product_size}"
    end
  end
  
  def get_gift_event_product_colors
    @product_colors = Color.joins(product_colors: [product: [stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).select(:id, :code, :name).where(["products.code = ?", params[:product_code].upcase]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).where("stock_details.color_id = common_fields.id").distinct
  end
  
  def get_gift_event_product_sizes
    @product_sizes = Size.joins(size_group: [products: [:product_colors, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).select(:id, :size).where(["products.code = ? AND product_colors.color_id = ?", params[:product_code].upcase, params[:product_color]]).where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).where("stock_details.color_id = product_colors.color_id AND stock_details.size_id = sizes.id").order(:size_order)
  end

  private
  
  def convert_money_to_numeric
    params[:sale][:cash] = params[:sale][:cash].gsub("Rp","").gsub(".","").gsub(",",".") if params[:sale][:cash].present?
    params[:sale][:pay] = params[:sale][:pay].gsub("Rp","").gsub(".","").gsub(",",".") if params[:sale][:pay].present?
  end
  
  def set_total
    @total = 0
    @minimum_purchase_amount = 0
    params[:sale][:sale_products_attributes].each do |key, value|
      price = session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["effective_price"]
      quantity = 1
      if session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"].present?
        if session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(%)") && session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"].present? && session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["second_plus_discount"].present?
          first_discounted_subtotal = price * quantity - price * quantity * session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"] / 100
          subtotal = first_discounted_subtotal - first_discounted_subtotal * session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["second_plus_discount"] / 100
          @total += subtotal
        elsif session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(%)") && session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"].present?
          subtotal = price * quantity - price * quantity * session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"] / 100
          @total += subtotal
        elsif session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(Rp)") && session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["cash_discount"].present?
          subtotal = price * quantity - session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["cash_discount"].to_f
          @total += subtotal
        elsif session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Special Price")
          price = session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["special_price"].to_f
          @total += price
        elsif session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Gift")
          @total += price
          @minimum_purchase_amount = session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["minimum_purchase_amount"].to_f
          @discount_amount = session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["discount_amount"].to_f
        else
          @total += price
        end
      else
        @total += price
      end
    end if params[:sale][:sale_products_attributes].present?
  end
  
  def add_additional_params_to_sale
    warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
    params[:sale].merge! warehouse_id: warehouse_id, cashier_id: current_user.id
    if @total >= @minimum_purchase_amount && @minimum_purchase_amount > 0
      if params[:sale][:gift_event_gift_type].strip.eql?("Discount")
        params[:sale].merge! gift_event_id: session["sale"]["event"]["id"], gift_event_discount_amount: session["sale"]["event"]["discount_amount"]
      elsif params[:sale][:gift_event_gift_type].strip.eql?("Product")
        params[:sale].merge! gift_event_id: session["sale"]["event"]["id"], gift_event_product_id: session["sale"]["gift_event_product_id"]
      end
    end
  end

  def add_additional_params_to_sale_products
    params[:sale][:sale_products_attributes].each do |key, value|
      if session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"].present?
        if session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Special Price")
          params[:sale][:sale_products_attributes][key].merge! sales_promotion_girl_id: current_user.sales_promotion_girl_id, effective_price: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["special_price"], price_list_id: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["price_list_id"]
        else
          params[:sale][:sale_products_attributes][key].merge! sales_promotion_girl_id: current_user.sales_promotion_girl_id, effective_price: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["effective_price"], price_list_id: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["price_list_id"]
        end
        params[:sale][:sale_products_attributes][key][:event_id] = session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["id"]
        params[:sale][:sale_products_attributes][key].merge! event_type: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"]
        if session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]][key].present? && session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]][key]["free_product_id"].present?
          params[:sale][:sale_products_attributes][key][:free_product_id] = session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]][key]["free_product_id"]
        else
          params[:sale][:sale_products_attributes][key][:free_product_id] = nil
        end
        if session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(%)")
          if session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"].present? && session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["second_plus_discount"].present?
            params[:sale][:sale_products_attributes][key].merge! first_plus_discount: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"], second_plus_discount: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["second_plus_discount"]
          elsif session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"].present?
            params[:sale][:sale_products_attributes][key].merge! first_plus_discount: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"]
          end
        elsif session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(Rp)")
          params[:sale][:sale_products_attributes][key].merge! cash_discount: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["cash_discount"]
        end
      else
        params[:sale][:sale_products_attributes][key].merge! sales_promotion_girl_id: current_user.sales_promotion_girl_id, effective_price: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["effective_price"], price_list_id: session["sale"][params[:sale][:sale_products_attributes][key][:product_barcode_id]]["price_list_id"]
        params[:sale][:sale_products_attributes][key][:event_id] = nil
        params[:sale][:sale_products_attributes][key].merge! event_type: nil, quantity: 1
        params[:sale][:sale_products_attributes][key][:free_product_id] = nil
      end
    end if params[:sale][:sale_products_attributes].present?
  end
  
  # Use callbacks to share common setup or constraints between actions.
  def set_sale
    @sale = Sale.joins(cashier_opening: [warehouse: :sales_promotion_girls]).
      joins("LEFT JOIN members on members.id = sales.member_id").
      joins("LEFT JOIN banks on banks.id = sales.bank_id").
      joins("LEFT JOIN stock_details on sales.gift_event_product_id = stock_details.id").
      joins("LEFT JOIN stock_products on stock_details.stock_product_id = stock_products.id").
      joins("LEFT JOIN products on stock_products.product_id = products.id").
      joins("LEFT JOIN common_fields on common_fields.id = products.brand_id AND common_fields.type IN ('Brand')").
      joins("LEFT JOIN sizes ON stock_details.size_id = sizes.id").
      joins("LEFT JOIN common_fields colors_products ON colors_products.id = stock_details.color_id AND colors_products.type IN ('Color')").
      joins("LEFT JOIN events ON events.id = sales.gift_event_id").
      select(:id, "warehouses.name AS warehouse_name, warehouses.address AS warehouse_address, sales.bank_id, sales.gift_event_id, sales.member_id, members.member_id AS member_identifier, members.name AS member_name, sales.transaction_time, sales.payment_method, sales.total, sales.cash, sales.change, sales.transaction_number, banks.code AS bank_code, banks.name AS bank_name, banks.card_type, sales.card_number, sales.trace_number, products.code AS product_code, common_fields.code AS brand_code, common_fields.name AS brand_name, sizes.size AS product_size, colors_products.code AS color_code, colors_products.name AS color_name, events.event_type, events.discount_amount, sales.gift_event_product_id, sales_promotion_girls.identifier AS cashier_identifier, sales_promotion_girls.name AS cashier_name, warehouses.first_message, warehouses.second_message, warehouses.third_message, warehouses.fourth_message, warehouses.fifth_message").
      where(id: params[:id]).where(["sales_promotion_girls.id = ?", current_user.sales_promotion_girl_id]).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def sale_params
    params.require(:sale).permit(:gift_event_discount_amount, :gift_event_gift_type, :gift_event_id, :gift_event_product_id, :pay, :warehouse_id, :cashier_id, :member_id, :transaction_time, :bank_id, :payment_method, :total, :trace_number, :card_number, :cash, :change, :transaction_number, :cashier_opening_id,
      sale_products_attributes: [:price_list_id, :effective_price, :event_type, :sales_promotion_girl_id, :quantity, :product_barcode_id, :event_id, :free_product_id, :first_plus_discount, :second_plus_discount, :cash_discount])
  end
end
