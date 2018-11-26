class Api::ConsignmentSalesController < Api::ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]
  before_action :authenticate_user!
  authorize_resource
  before_action :set_consignment_sale, only: [:approve, :unapprove, :destroy]

  # GET /consignment_sales/new
  #  def new
  #    @counters = if current_user.has_role?(:area_manager)
  #      current_user.supervisor.warehouses.counter.select(:id, :code, :name)
  #    elsif current_user.has_non_spg_role?
  #      Warehouse.select(:id, :code, :name).counter
  #    end
  #  end
  
  def index        
    warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
    @consignment_sales = ConsignmentSale.select(:id, :transaction_date, :transaction_number, :total, :approved, :no_sale).where(["consignment_sales.warehouse_id = ?", warehouse_id]).order(:transaction_number)
  end
  
  def get_events
    #    @events = if current_user.has_non_spg_role?
    #      CounterEvent.select(:id, :code, :name).joins(:counter_event_warehouses).where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_event_warehouses.warehouse_id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, params[:warehouse_id], true, true])
    #    else
    #      CounterEvent.select(:id, :code, :name).joins(:counter_event_warehouses).where(["DATE(counter_events.start_time) <= ? AND DATE(counter_events.end_time) >= ? AND counter_event_warehouses.warehouse_id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date, params[:transaction_date].to_date, current_user.sales_promotion_girl.warehouse_id, true, true])
    #    end      
    @events = CounterEvent.select(:id, :code, :name).joins(:counter_event_warehouses).where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_event_warehouses.warehouse_id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, current_user.sales_promotion_girl.warehouse_id, true, true])
  end
  
  def get_product
    #    render json: { status: false, message: "Please fill in transaction date first" }, status: :unprocessable_entity and return if params[:transaction_date].blank?
    render json: { status: false, message: "Please fill in transaction date first" } and return if params[:transaction_date].blank?

    @product = if params[:counter_event_id].blank?
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
    
    if @product.nil?
      render json: { status: false, message: "Product #{params[:barcode]} is not available" }#, status: :unprocessable_entity
    else
      #  var unapprovedQty = <%= @product.unapproved_quantity %>;
      if @product.quantity < 1
        render json: { status: false, message: "Sorry, product #{@product.barcode} is temporarily out of stock" }#, status: :unprocessable_entity
      elsif @product.quantity - @product.unapproved_quantity < 1
        render json: { status: false, message: "Sorry, product #{@product.barcode} is temporarily out of stock" }#, status: :unprocessable_entity
      else
        # hitung total stok receiving DO di tanggal setelah tanggal transaksi penjualan
        shipment_items = ShipmentProductItem.
          joins(order_booking_product_item: [order_booking_product: :order_booking], shipment_product: :shipment).
          where(["order_booking_product_items.size_id = ? AND order_booking_product_items.color_id = ?", @product.product_size_id, @product.product_color_id]).
          where(["order_booking_products.product_id = ?", @product.product_id]).
          where(["order_bookings.destination_warehouse_id = ?", @product.warehouse_id]).
          where(["shipments.received_date > ?", params[:transaction_date].to_date]).
          select(:quantity, "shipments.received_date").order("shipments.received_date ASC")
          
        # hitung total stok rolling in di tanggal setelah tanggal transaksi penjualan
        stock_mutation_product_items = StockMutationProductItem.
          joins(stock_mutation_product: :stock_mutation).
          where(["stock_mutation_product_items.size_id = ? AND stock_mutation_product_items.color_id = ?", @product.product_size_id, @product.product_color_id]).
          where(["stock_mutation_products.product_id = ?", @product.product_id]).
          where(["stock_mutations.destination_warehouse_id = ?", @product.warehouse_id]).
          where(["stock_mutations.received_date > ?", params[:transaction_date].to_date]).
          select(:quantity, "stock_mutations.received_date").order("stock_mutations.received_date ASC")

        # hitung total stok adjustment in di tanggal setelah tanggal transaksi penjualan
#        adjustment_product_details = AdjustmentProductDetail.
#          select(:quantity).joins(adjustment_product: :adjustment).
#          where(["adjustment_product_details.size_id = ? AND adjustment_product_details.color_id = ?", @product.product_size_id, @product.product_color_id]).
#          where(["adjustment_products.product_id = ?", @product.product_id]).
#          where(["adjustments.warehouse_id = ? AND adjustments.adj_type = 'In'", @product.warehouse_id]).
#          where(["adjustments.adj_date > ?", params[:transaction_date].to_date]).
#          order("adjustments.adj_date ASC")

        # hitung total stok rolling out di tanggal setelah tanggal transaksi penjualan
        rolling_out_items = StockMutationProductItem.
          joins(stock_mutation_product: [stock_mutation: :destination_warehouse]).
          where(["stock_mutation_product_items.size_id = ? AND stock_mutation_product_items.color_id = ?", @product.product_size_id, @product.product_color_id]).
          where(["stock_mutation_products.product_id = ?", @product.product_id]).
          where(["stock_mutations.origin_warehouse_id = ?", @product.warehouse_id]).
          where("warehouses.warehouse_type <> 'central'").
          where(["stock_mutations.delivery_date > ?", params[:transaction_date].to_date]).
          select(:quantity).order("stock_mutations.delivery_date ASC")

        # hitung total stok return di tanggal setelah tanggal transaksi penjualan
        return_items = StockMutationProductItem.
          joins(stock_mutation_product: [stock_mutation: :destination_warehouse]).
          where(["stock_mutation_product_items.size_id = ? AND stock_mutation_product_items.color_id = ?", @product.product_size_id, @product.product_color_id]).
          where(["stock_mutation_products.product_id = ?", @product.product_id]).
          where(["stock_mutations.origin_warehouse_id = ?", @product.warehouse_id]).
          where("warehouses.warehouse_type = 'central'").
          where(["stock_mutations.delivery_date > ?", params[:transaction_date].to_date]).
          select(:quantity).order("stock_mutations.delivery_date ASC")

        do_qty_on_hand = shipment_items.present? ? shipment_items.sum(&:quantity) : 0
        mutation_qty_on_hand = stock_mutation_product_items.present? ? stock_mutation_product_items.sum(&:quantity) : 0
#        adj_in_qty_on_hand = adjustment_product_details.present? ? adjustment_product_details.sum(&:quantity) : 0
        rolling_out_qty = rolling_out_items.present? ? rolling_out_items.sum(&:quantity) : 0
        return_qty = return_items.present? ? return_items.sum(&:quantity) : 0
        # QOH sebelum DO dan mutation masuk di tanggal sesudah tanggal transaksi penjualan
#        final_qty_on_hand = @product.quantity - (do_qty_on_hand + mutation_qty_on_hand + adj_in_qty_on_hand - rolling_out_qty - return_qty)
        final_qty_on_hand = @product.quantity - (do_qty_on_hand + mutation_qty_on_hand - rolling_out_qty - return_qty)
        # apabila di tanggal transaksi qty on hand < added qty
        if final_qty_on_hand < 1
          render json: { status: false, message: "Sorry, available quantity of product #{@product.barcode} on #{params[:transaction_date]} is #{final_qty_on_hand}" }#, status: :unprocessable_entity
        else
#          if do_qty_on_hand > 0 || mutation_qty_on_hand > 0 || adj_in_qty_on_hand > 0 || rolling_out_qty > 0 || return_qty > 0
          if do_qty_on_hand > 0 || mutation_qty_on_hand > 0 || rolling_out_qty > 0 || return_qty > 0
            # htung jumlah barang yang sudah dipesan dari tanggal transaksi pnjualan ke belakang
            booked_quantity = ConsignmentSaleProduct.joins(:consignment_sale).
              where(["consignment_sale_products.product_barcode_id = ? AND consignment_sales.approved = ? AND consignment_sales.transaction_date <= ? AND consignment_sales.warehouse_id = ?", @product.id, false, params[:transaction_date].to_date, @product.warehouse_id]).
              size
            if final_qty_on_hand - booked_quantity < 1
              render json: { status: false, message: "Sorry, product #{@product.barcode} on #{params[:transaction_date]} is temporarily out of stock" }#, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
  
  def create
    #    render json: { status: false, message: "Please fill in transaction date first" }, status: :unprocessable_entity and return if params[:consignment_sale][:transaction_date].blank?
    render json: { status: false, message: "Please fill in transaction date first" } and return if params[:transaction_date].blank?

    spg = SalesPromotionGirl.joins(:warehouse).select(:warehouse_id, "warehouses.code").where(id: current_user.sales_promotion_girl_id).first
    @consignment_sale = ConsignmentSale.new(no_sale: params[:no_sale], transaction_date: params[:transaction_date], counter_event_id: params[:counter_event_id])
    @consignment_sale.warehouse_id = spg.warehouse_id
    @consignment_sale.attr_create_by_am = false
    @consignment_sale.attr_warehouse_code = spg.code
    calculate_total unless params[:no_sale].eql?("true")
    
    recreate = false
    recreate_counter = 1

    begin
      begin
        recreate = false
        unless @consignment_sale.save
          if @consignment_sale.errors[:base].present?
            render json: { status: false, message: @consignment_sale.errors[:base].first }#, status: :unprocessable_entity
          elsif @consignment_sale.errors[:"consignment_sale_products.base"].present?
            render json: { status: false, message: @consignment_sale.errors[:"consignment_sale_products.base"].first }#, status: :unprocessable_entity
          end
        else
          render json: { status: true, message: "Transaction was successfully created" }
        end
      rescue ActiveRecord::RecordNotUnique => e
        if recreate_counter < 5
          recreate = true
          recreate_counter += 1
        else
          recreate = false
          render json: { status: false, message: "Something went wrong. Please try again" }#, status: :unprocessable_entity
        end
      rescue RuntimeError => e
        recreate = false
        render json: { status: false, message: e.message }#, status: :unprocessable_entity
      end
    end while recreate
  end

  def approve
    @consignment_sale.attr_spg_warehouse_id = current_user.sales_promotion_girl.warehouse_id
    begin
      unless @consignment_sale.update(approved: true)
        render json: { status: false, message: @consignment_sale.errors[:base].first }, status: :unprocessable_entity
      else
        render json: { status: true, message: "Transaction #{@consignment_sale.transaction_number} was successfully approved" }
      end
    rescue RuntimeError => e
      render json: { status: false, message: e.message }, status: :unprocessable_entity
    end
  end
  
  def unapprove
    @consignment_sale.attr_spg_warehouse_id = current_user.sales_promotion_girl.warehouse_id
    begin
      unless @consignment_sale.update(approved: false)
        render json: { status: false, message: @consignment_sale.errors[:base].first }, status: :unprocessable_entity
      else
        render json: { status: true, message: "Transaction #{@consignment_sale.transaction_number} was successfully disapproved" }
      end
    rescue RuntimeError => e
      render json: { status: false, message: e.message }, status: :unprocessable_entity
    end
  end
  
  def destroy
    begin
      warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
      @consignment_sale.attr_spg_warehouse_id = warehouse_id
      @consignment_sale.consignment_sale_products.each do |consignment_sale_product|
        consignment_sale_product.attr_warehouse_id = warehouse_id
      end
      if @consignment_sale.destroy
        render json: { status: true, message: "Transaction #{@consignment_sale.transaction_number} was successfully deleted" }
      end
    rescue RuntimeError => e
      render json: { status: false, message: e.message }#, status: :unprocessable_entity
    end
  end
  
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
    @consignment_sale_products = @consignment_sale.consignment_sale_products.
      joins(:price_list, product_barcode: [:size, product_color: [:color, [product: :brand]]]).
      select("product_barcodes.barcode", "brands_products.name AS product_name", "products.code AS product_code", "common_fields.code AS color_code", "common_fields.name AS color_name", "sizes.size AS product_size", "price_lists.price", "consignment_sale_products.total AS subtotal")
  end

  private
  
  #  def add_additional_params_to_consignment_sales
  #    spg = SalesPromotionGirl.joins(:warehouse).select(:warehouse_id, "warehouses.code").where(id: current_user.sales_promotion_girl_id).first
  #    @warehouse_id = spg.warehouse_id
  #    @warehouse_code = spg.code
  #    params[:consignment_sale].merge! attr_warehouse_code: @warehouse_code
  #  end
  
  def consignment_sale_params
    unless action_name.eql?("update")
      params.require(:consignment_sale).permit(:no_sale, :counter_event_id, :total, :attr_warehouse_code, :transaction_date,
        consignment_sale_products_attributes: [:product_barcode_id, :price_list_id, :total, :attr_warehouse_id, :attr_barcode, :attr_transaction_date, :attr_no_sale])
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

  def calculate_total
    total = 0
    params[:products].each do |param_product|
      product = if params[:counter_event_id].blank?
        ProductBarcode.joins(product_color: [product: [product_details: :price_lists, stock_products: [stock: [warehouse: :sales_promotion_girls]]]]).
          where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, id: param_product[:product_barcode_id]).
          where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id").
          where(["effective_date <= ?", params[:transaction_date].to_date]).
          select(:barcode, "price_lists.price, price_lists.id AS price_list_id").
          order("effective_date DESC").
          first
      else
        ProductBarcode.joins(product_color: [product: [product_details: :price_lists, stock_products: [stock: [warehouse: [:sales_promotion_girls, counter_event_warehouses: :counter_event]]]]]).
          where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, id: param_product[:product_barcode_id]).
          where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id").
          where(["effective_date <= ?", params[:transaction_date].to_date]).
          where(["counter_events.start_time <= ? AND counter_events.end_time >= ? AND counter_events.id = ? AND (counter_events.is_active = ? OR counter_event_warehouses.is_active = ?)", params[:transaction_date].to_date.end_of_day, params[:transaction_date].to_date.beginning_of_day, params[:counter_event_id], true, true]).
          select(:barcode, "price_lists.price, price_lists.id AS price_list_id").
          select("counter_events.counter_event_type, counter_events.first_discount, counter_events.second_discount, counter_events.special_price").
          order("effective_date DESC").
          first
      end
      subtotal = if params[:counter_event_id].present? && product.counter_event_type.present?
        if product.counter_event_type.eql?("Discount(%)") && product.first_discount.present? && product.second_discount.present?
          first_discounted_subtotal = product.price - product.price * product.first_discount / 100
          first_discounted_subtotal - first_discounted_subtotal * product.second_discount / 100
        elsif product.counter_event_type.eql?("Discount(%)") && product.first_discount.present?
          product.price - product.price * product.first_discount / 100
        elsif product.counter_event_type.eql?("Special Price") && product.special_price.present?
          product.special_price
        end
      else
        @consignment_sale.counter_event_id = params[:counter_event_id] = nil if params[:counter_event_id].present?
        product.price
      end
      @consignment_sale.consignment_sale_products.build price_list_id: product.price_list_id, total: subtotal, attr_warehouse_id: @consignment_sale.warehouse_id, attr_barcode: product.barcode, attr_transaction_date: params[:transaction_date], attr_no_sale: params[:no_sale], product_barcode_id: param_product[:product_barcode_id]
      total += subtotal
    end if params[:products].present?
    @consignment_sale.total = total
  end

  def set_consignment_sale
    @consignment_sale = ConsignmentSale.find(params[:id])
  end

end
