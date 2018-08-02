include SmartListing::Helper::ControllerExtensions
class SalesReturnsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_sales_return, only: [:edit, :update, :destroy]

  # GET /sales_returns
  # GET /sales_returns.json
  def index
    like_command = "ILIKE"
    
    if params[:filter_date].present?
      splitted_date_range = params[:filter_date].split("-")
      start_date = Time.zone.parse(splitted_date_range[0].strip)
      end_date = Time.zone.parse(splitted_date_range[1].strip).end_of_day
    end

    sales_returns_scope = SalesReturn.joins(:returned_receipt).select(:id, :total_return, :total_return_quantity, :document_number, :created_at).select("sales.transaction_number")
    sales_returns_scope = sales_returns_scope.where(["document_number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(sales_returns_scope.where(["sales.transaction_number #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string]
    sales_returns_scope = sales_returns_scope.where(["sales_returns.created_at BETWEEN ? AND ?", start_date, end_date]) if params[:filter_date].present?
    smart_listing_create(:sales_returns, sales_returns_scope, partial: 'sales_returns/listing', default_sort: {:"sales_returns.created_at" => "desc"})
  end

  # GET /sales_returns/1
  # GET /sales_returns/1.json
  def show
    @sales_return = SalesReturn.select(:id, :total_return, :total_return_quantity, :document_number, :created_at, "sales.transaction_number").joins(:returned_receipt).find(params[:id])
  end

  # GET /sales_returns/new
  def new
    @sales_return = SalesReturn.new
  end

  # GET /sales_returns/1/edit
  def edit
  end

  # POST /sales_returns
  # POST /sales_returns.json
  def create
    convert_money_to_numeric
    add_additional_params_to_sales_return
    set_total
    params[:sales_return][:sale_attributes].merge! total: @total

    @sales_return = SalesReturn.new(sales_return_params)
    recreate = false
    recreate_counter = 1
    begin
      begin
        recreate = false
        unless @sales_return.save
          if @sales_return.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@sales_return.errors[:base].join("<br/>")}\",size: 'small'});"
          elsif @sales_return.errors["sale.base"].present?
            render js: "bootbox.alert({message: \"#{@sales_return.errors["sale.base"].join("<br/>")}\",size: 'small'});"
          elsif @sales_return.errors["sale.payment_method"].present?
            render js: "bootbox.alert({message: \"#{@sales_return.errors["sale.payment_method"].join("<br/>")}\",size: 'small'});"
          elsif @sales_return.errors["sale.bank_id"].present?
            render js: "bootbox.alert({message: \"#{@sales_return.errors["sale.bank_id"].join("<br/>")}\",size: 'small'});"
          elsif @sales_return.errors["sale.trace_number"].present?
            render js: "bootbox.alert({message: \"#{@sales_return.errors["sale.trace_number"].join("<br/>")}\",size: 'small'});"
          elsif @sales_return.errors["sale.card_number"].present?
            render js: "bootbox.alert({message: \"#{@sales_return.errors["sale.card_number"].join("<br/>")}\",size: 'small'});"
          elsif @sales_return.errors["sale.cash"].present?
            render js: "bootbox.alert({message: \"#{@sales_return.errors["sale.cash"].join("<br/>")}\",size: 'small'});"
          end
        else
          @sale = Sale.joins(returned_document: :returned_receipt, cashier_opening: [warehouse: :sales_promotion_girls]).
            joins("LEFT JOIN members on members.id = sales.member_id").
            joins("LEFT JOIN banks on banks.id = sales.bank_id").
            #            joins("LEFT JOIN stock_details on sales.gift_event_product_id = stock_details.id").
          #            joins("LEFT JOIN stock_products on stock_details.stock_product_id = stock_products.id").
          #            joins("LEFT JOIN products on stock_products.product_id = products.id").
          #            joins("LEFT JOIN sizes ON stock_details.size_id = sizes.id").
          #            joins("LEFT JOIN common_fields colors_products ON colors_products.id = stock_details.color_id AND colors_products.type IN ('Color')").
          #            joins("LEFT JOIN events ON events.id = sales.gift_event_id").
          #          select(:id, "warehouses.name AS warehouse_name, warehouses.address AS warehouse_address, sales.bank_id, sales.gift_event_id, sales.member_id, members.member_id AS member_identifier, members.name AS member_name, sales.transaction_time, sales.payment_method, sales.total, sales.cash, sales.change, sales.transaction_number, banks.code AS bank_code, banks.name AS bank_name, banks.card_type, sales.card_number, sales.trace_number, products.code AS product_code, sizes.size AS product_size, colors_products.code AS color_code, colors_products.name AS color_name, events.event_type, events.discount_amount, sales.gift_event_product_id, sales_promotion_girls.identifier AS cashier_identifier, sales_promotion_girls.name AS cashier_name, warehouses.first_message, warehouses.second_message, warehouses.third_message, warehouses.fourth_message, warehouses.fifth_message, sales_returns.total_return, returned_receipts_sales_returns.transaction_number AS returned_receipt_transaction_number").
          select(:id, "warehouses.name AS warehouse_name, warehouses.address AS warehouse_address, sales.bank_id, sales.gift_event_id, sales.member_id, members.member_id AS member_identifier, members.name AS member_name, sales.transaction_time, sales.payment_method, sales.total, sales.cash, sales.change, sales.transaction_number, banks.code AS bank_code, banks.name AS bank_name, banks.card_type, sales.card_number, sales.trace_number, sales.gift_event_product_id, sales_promotion_girls.identifier AS cashier_identifier, sales_promotion_girls.name AS cashier_name, warehouses.first_message, warehouses.second_message, warehouses.third_message, warehouses.fourth_message, warehouses.fifth_message, sales_returns.total_return, returned_receipts_sales_returns.transaction_number AS returned_receipt_transaction_number").
            where(sales_return_id: @sales_return.id).where(["sales_promotion_girls.id = ?", current_user.sales_promotion_girl_id]).first
          @returned_receipt_number = @sale.returned_receipt_transaction_number
        end
      rescue ActiveRecord::RecordNotUnique => e
        if recreate_counter < 3
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
  
  # PATCH/PUT /sales_returns/1
  # PATCH/PUT /sales_returns/1.json
  def update
    respond_to do |format|
      if @sales_return.update(sales_return_params)
        format.html { redirect_to @sales_return, notice: 'Sales return was successfully updated.' }
        format.json { render :show, status: :ok, location: @sales_return }
      else
        format.html { render :edit }
        format.json { render json: @sales_return.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sales_returns/1
  # DELETE /sales_returns/1.json
  def destroy
    @sales_return.destroy
    respond_to do |format|
      format.html { redirect_to sales_returns_url, notice: 'Sales return was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def search_receipt
    @sale_products = SaleProduct.
      joins(sale: [cashier_opening: [warehouse: :sales_promotion_girls]], product_barcode: [:size, product_color: [:color, :product]]).
      joins("LEFT JOIN sales_returns ON sales_returns.sale_id = sales.id").
      select(:id, :total, :sale_id, "sizes.size AS product_size", "common_fields.name AS product_color", "products.code AS product_code", "sales.transaction_time", "sales.gift_event_id", "sales.member_id", "sales_returns.sale_id AS returned_sale_id").
      where(["sales.transaction_number = ? AND warehouses.is_active = ?", params[:receipt_number].upcase, true]).
      where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id)
    # ambil member id pembeli dan simpan ke dalam session
    if @sale_products.present?
      session["member_id"] = @sale_products.first.member_id
    end
  end
  
  def get_replacement_product
    @returned_product = SaleProduct.
      joins(:price_list, sale: [cashier_opening: :warehouse], product_barcode: [:size, product_color: [:color, product: :brand]]).
      joins("LEFT JOIN events on events.id = sale_products.event_id").
      where(id: params[:sale_product_id], :"warehouses.is_active" => true).
      select(:id, :barcode).
      select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, sale_products.sale_id, first_plus_discount AS event_first_plus_discount, second_plus_discount AS event_second_plus_discount, sale_products.total, sales.transaction_time, cash_discount AS event_cash_discount, special_price, events.event_type AS product_event, sale_products.event_id AS returned_product_event_id").
      first
    
    # product return yang mengikuti BOGOF tidak dapat diretur
    if @returned_product.product_event.eql?("Buy 1 Get 1 Free")
      render js: "bootbox.alert({message: \"Sorry, product #{@returned_product.barcode} can't be returned because it has event(BOGOF)\",size: 'small'});"
    else
      @replacement_product = if params[:barcode]
        ProductBarcode.
          joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).
          where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, barcode: params[:barcode]).
          where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
          where(["effective_date <= ? AND warehouses.is_active = ?", @returned_product.transaction_time.to_date, true]).
          select(:id, :barcode).
          select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stocks.warehouse_id").
          order("effective_date DESC").
          first
      else
        ProductBarcode.
          joins(:size, product_color: [:color, product: [:brand, product_details: :price_lists, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).
          where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id, size_id: params[:replacement_product_size]).
          where("product_details.size_id = product_barcodes.size_id AND product_details.price_code_id = warehouses.price_code_id AND stock_details.size_id = product_barcodes.size_id AND stock_details.color_id = product_colors.color_id").
          where(["effective_date <= ?", @returned_product.transaction_time.to_date]).
          where(["product_colors.color_id = ? AND products.code = ? AND warehouses.is_active = ?", params[:replacement_product_color], params[:replacement_product_code].upcase, true]).
          select(:id, :barcode).
          select("size AS product_size, common_fields.code AS color_code, common_fields.name AS color_name, products.code AS product_code, brands_products.name AS brand_name, price_lists.price, product_colors.product_id, stock_details.id AS stock_detail_id, price_lists.id AS price_list_id, stocks.warehouse_id").
          order("effective_date DESC").
          first
      end

      if @replacement_product.present?
        # apabila harga barang pengganti lebih murah dari harga barang retur maka tidak valid
        if @returned_product.price > @replacement_product.price && @returned_product.barcode != @replacement_product.barcode
          render js: "bootbox.alert({message: \"Replacement product price must be greater than or equal to returned product price\",size: 'small'});"
        else
          @store_event = nil
          unless @returned_product.barcode == @replacement_product.barcode
            # event selain GIFT berlaku di barang pengganti
            event_specific_product = Event.joins(event_warehouses: :event_products).select(:created_at, :id, :first_plus_discount, :second_plus_discount, :cash_discount, :special_price, :event_type, :minimum_purchase_amount, :discount_amount).where(["start_date_time <= ? AND end_date_time > ? AND event_warehouses.warehouse_id = ? AND event_products.product_id = ? AND select_different_products = ? AND (events.is_active = ? OR event_warehouses.is_active = ?) AND event_type <> 'Gift'", @returned_product.transaction_time, @returned_product.transaction_time, @replacement_product.warehouse_id, @replacement_product.product_id, true, true, true]).order("events.created_at DESC").first
            event_general_product = Event.joins(:event_warehouses, :event_general_products).select(:created_at, :id, :first_plus_discount, :second_plus_discount, :cash_discount, :special_price, :event_type, :minimum_purchase_amount, :discount_amount).where(["start_date_time <= ? AND end_date_time > ? AND event_warehouses.warehouse_id = ? AND event_general_products.product_id = ? AND (select_different_products = ? OR select_different_products IS NULL) AND (events.is_active = ? OR event_warehouses.is_active = ?) AND event_type <> 'Gift'", @returned_product.transaction_time, @returned_product.transaction_time, @replacement_product.warehouse_id, @replacement_product.product_id, false, true, true]).order("events.created_at DESC").first
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
            end
          else
            # apabila barang retur dan pengganti sama maka event barang pengganti sama dengan event barang retur
            if @returned_product.product_event.present?
              event = Event.select(:id, :event_type, :first_plus_discount, :second_plus_discount, :cash_discount, :special_price).where(id: @returned_product.returned_product_event_id).first
              @store_event = event
            end
          end
                  
          if @store_event.blank?
            # apabila harga net barang retur lebih besar dari harga barang pengganti maka invalid
            if @returned_product.total > @replacement_product.price && @returned_product.barcode != @replacement_product.barcode
              render js: "bootbox.alert({message: \"Replacement product net price must be greater than or equal to returned product net price\",size: 'small'});"
            else
              @sales_return = SalesReturn.new sale_id: @returned_product.sale_id, attr_receipt_number: params[:receipt_number].upcase
              @sales_return_product = @sales_return.sales_return_products.build sale_product_id: @returned_product.id
              sale = @sales_return.build_sale
              @sale_product = sale.sale_products.build product_barcode_id: @replacement_product.id, quantity: 1, returned_product_id: @returned_product.id
            end
          else
            if @store_event.event_type.eql?("Buy 1 Get 1 Free")
              render js: "bootbox.alert({message: \"Sorry, you can't use product #{@replacement_product.barcode} to replace product #{@returned_product.barcode} because it has event(BOGOF)\",size: 'small'});"
            else
              subtotal = if @store_event.event_type.eql?("Discount(%)") && @store_event.first_plus_discount.present? && @store_event.second_plus_discount.present?
                first_discounted_subtotal = @replacement_product.price - @replacement_product.price * @store_event.first_plus_discount / 100
                first_discounted_subtotal - first_discounted_subtotal * @store_event.second_plus_discount / 100
              elsif @store_event.event_type.eql?("Discount(%)") && @store_event.first_plus_discount.present?
                @replacement_product.price - @replacement_product.price * @store_event.first_plus_discount / 100
              elsif @store_event.event_type.eql?("Special Price") && @store_event.special_price.present?
                @store_event.special_price
              elsif @store_event.event_type.eql?("Discount(Rp)") && @store_event.cash_discount.present?
                @replacement_product.price - @store_event.cash_discount
              end
          
              # apabila harga net barang retur lebih besar dari harga net (sudah dipotong event) barang pengganti maka invalid
              if @returned_product.total > subtotal && @returned_product.barcode != @replacement_product.barcode
                render js: "bootbox.alert({message: \"Replacement product net price must be greater than or equal to returned product net price\",size: 'small'});"
              else
                @sales_return = SalesReturn.new sale_id: @returned_product.sale_id, attr_receipt_number: params[:receipt_number].upcase
                @sales_return_product = @sales_return.sales_return_products.build sale_product_id: @returned_product.id
                sale = @sales_return.build_sale      
                @sale_product = sale.sale_products.build product_barcode_id: @replacement_product.id, quantity: 1, event_id: @store_event.id, returned_product_id: @returned_product.id
              end
            end
          end
        end
      end
    end    
  end
  
  def get_replacement_product_colors
    @replacement_product_colors = Color.joins(product_colors: [product: [stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).
      select(:id, :code, :name).
      where(["products.code = ? AND warehouses.is_active = ?", params[:replacement_product_code].upcase, true]).
      where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).
      where("stock_details.color_id = common_fields.id").distinct
  end

  def get_replacement_product_sizes
    @replacement_product_sizes = Size.joins(size_group: [products: [:product_colors, stock_products: [:stock_details, stock: [warehouse: :sales_promotion_girls]]]]).
      select(:id, :size).
      where(["products.code = ? AND product_colors.color_id = ? AND warehouses.is_active = ?", params[:replacement_product_code].upcase, params[:replacement_product_color], true]).
      where(:"sales_promotion_girls.id" => current_user.sales_promotion_girl_id).
      where("stock_details.color_id = product_colors.color_id AND stock_details.size_id = sizes.id").
      order(:size_order)
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_sales_return
    @sales_return = SalesReturn.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def sales_return_params
    params.require(:sales_return).permit(:sale_id, :total_return, :total_return_quantity, :attr_receipt_number, :attr_cashier_id, :attr_spg_id, 
      sale_attributes: [:payment_method, :cash, :bank_id, :card_number, :trace_number, :pay, :cashier_id, :attr_return_sale_products, :total, :warehouse_id, :member_id,
        sale_products_attributes: [:product_barcode_id, :event_id, :returned_product_id, :sales_promotion_girl_id, :effective_price, :price_list_id, :event_type, :free_product_id, :first_plus_discount, :second_plus_discount, :cash_discount, :quantity, :attr_returned_sale_id]],
      sales_return_products_attributes: [:reason, :sale_product_id, :attr_sale_id, :attr_warehouse_id])
  end
  
  def add_additional_params_to_sales_return
    warehouse_id = Warehouse.joins(:sales_promotion_girls).select(:id).where(["sales_promotion_girls.id = ? AND warehouses.warehouse_type = 'showroom'", current_user.sales_promotion_girl_id]).first.id
    params[:sales_return].merge! attr_cashier_id: current_user.id, attr_spg_id: current_user.sales_promotion_girl_id
    if session["member_id"].present?
      hash_params = {cashier_id: current_user.id, attr_return_sale_products: true, warehouse_id: warehouse_id, member_id: session["member_id"]}
    else
      hash_params = {cashier_id: current_user.id, attr_return_sale_products: true, warehouse_id: warehouse_id, member_id: nil}
    end
    params[:sales_return][:sale_attributes].merge! hash_params
    params[:sales_return][:sales_return_products_attributes].each do |key, value|
      params[:sales_return][:sales_return_products_attributes][key].merge! attr_sale_id: params[:sales_return][:sale_id], attr_warehouse_id: warehouse_id
    end #if params[:sales_return][:sales_return_products_attributes].present?
    
    params[:sales_return][:sale_attributes][:sale_products_attributes].each do |key, value|
      params[:sales_return][:sale_attributes][:sale_products_attributes][key].merge! attr_returned_sale_id: params[:sales_return][:sale_id], attr_returning_sale: true
      if session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"].present?
        if session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Special Price")
          params[:sales_return][:sale_attributes][:sale_products_attributes][key].merge! sales_promotion_girl_id: current_user.sales_promotion_girl_id, effective_price: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["special_price"], price_list_id: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["price_list_id"]
        else
          params[:sales_return][:sale_attributes][:sale_products_attributes][key].merge! sales_promotion_girl_id: current_user.sales_promotion_girl_id, effective_price: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["effective_price"], price_list_id: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["price_list_id"]
        end
        params[:sales_return][:sale_attributes][:sale_products_attributes][key][:event_id] = session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["id"]
        params[:sales_return][:sale_attributes][:sale_products_attributes][key].merge! event_type: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"]
        #        params[:sales_return][:sale_attributes][:sale_products_attributes][key][:free_product_id] = nil
        if session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(%)")
          if session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"].present? && session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["second_plus_discount"].present?
            params[:sales_return][:sale_attributes][:sale_products_attributes][key].merge! first_plus_discount: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"], second_plus_discount: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["second_plus_discount"]
          elsif session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"].present?
            params[:sales_return][:sale_attributes][:sale_products_attributes][key].merge! first_plus_discount: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"]
          end
        elsif session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(Rp)")
          params[:sales_return][:sale_attributes][:sale_products_attributes][key].merge! cash_discount: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["cash_discount"]
        end
      else
        params[:sales_return][:sale_attributes][:sale_products_attributes][key].merge! sales_promotion_girl_id: current_user.sales_promotion_girl_id, effective_price: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["effective_price"], price_list_id: session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["price_list_id"]
        params[:sales_return][:sale_attributes][:sale_products_attributes][key][:event_id] = nil
        params[:sales_return][:sale_attributes][:sale_products_attributes][key].merge! event_type: nil, quantity: 1
        #        params[:sales_return][:sale_attributes][:sale_products_attributes][key][:free_product_id] = nil
      end
    end #if params[:sales_return][:sale_attributes][:sale_products_attributes].present?

  end
  
  def convert_money_to_numeric
    params[:sales_return][:sale_attributes][:cash] = params[:sales_return][:sale_attributes][:cash].gsub("Rp","").gsub(".","").gsub(",",".") if params[:sales_return][:sale_attributes][:cash].present?
    params[:sales_return][:sale_attributes][:pay] = params[:sales_return][:sale_attributes][:pay].gsub("Rp","").gsub(".","").gsub(",",".") if params[:sales_return][:sale_attributes][:pay].present?
  end
  
  def set_total
    @total = 0
    params[:sales_return][:sale_attributes][:sale_products_attributes].each do |key, value|
      price = session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["effective_price"]
      quantity = 1
      if session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"].present?
        if session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(%)") && session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"].present? && session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["second_plus_discount"].present?
          first_discounted_subtotal = price * quantity - price * quantity * session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"] / 100
          subtotal = first_discounted_subtotal - first_discounted_subtotal * session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["second_plus_discount"] / 100
          @total += subtotal
        elsif session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(%)") && session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"].present?
          subtotal = price * quantity - price * quantity * session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["first_plus_discount"] / 100
          @total += subtotal
        elsif session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Discount(Rp)") && session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["cash_discount"].present?
          subtotal = price * quantity - session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["cash_discount"].to_f
          @total += subtotal
        elsif session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["event_type"].eql?("Special Price")
          price = session["sales_return"][params[:sales_return][:sale_attributes][:sale_products_attributes][key][:product_barcode_id]]["store_event"]["special_price"].to_f
          @total += price
        else
          @total += price
        end
      else
        @total += price
      end
    end if params[:sales_return][:sale_attributes][:sale_products_attributes].present?
  end


end
