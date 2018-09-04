include SmartListing::Helper::ControllerExtensions
class ListingStocksController < ApplicationController
  authorize_resource
  helper SmartListing::Helper
  before_action :set_listing_stock, only: [:show, :edit, :update, :destroy]

  # GET /listing_stocks
  # GET /listing_stocks.json
  def index
    like_command = "ILIKE"
    listing_stock_transactions_scope = if params[:filter_warehouse].present?
      splitted_date = params[:filter_listing_transaction_date].split(" - ")
      ListingStockTransaction.
        joins(listing_stock_product_detail: [:color, :size, listing_stock: [:warehouse, product: :brand]]).
        select(:transaction_date, :transaction_number, :transaction_type, :quantity).
        select("products.code AS product_code, brands_products.name AS product_name, common_fields.code AS color_code, common_fields.name AS color_name, size, warehouses.warehouse_type").
        select("(SELECT price_lists.price FROM price_lists INNER JOIN product_details ON product_details.id = price_lists.product_detail_id WHERE (product_details.size_id = listing_stock_product_details.size_id AND product_details.product_id = listing_stocks.product_id AND product_details.price_code_id = warehouses.price_code_id) ORDER BY price_lists.effective_date ASC LIMIT 1) AS product_first_price").
        select("((SELECT price_lists.price FROM price_lists INNER JOIN product_details ON product_details.id = price_lists.product_detail_id WHERE (product_details.size_id = listing_stock_product_details.size_id AND product_details.product_id = listing_stocks.product_id AND product_details.price_code_id = warehouses.price_code_id) ORDER BY price_lists.effective_date ASC LIMIT 1) * listing_stock_transactions.quantity) AS total_product_price").
        where(["transaction_date BETWEEN ? AND ? AND warehouse_id = ? AND warehouses.is_active = ?", splitted_date[0].to_date, splitted_date[1].to_date, params[:filter_warehouse], true])
    else
      ListingStockTransaction.none
    end

    listing_stock_transactions_scope = if params[:listing_stock_transactions_smart_listing].present? && params[:listing_stock_transactions_smart_listing][:sort].present?
      order_fields = if params[:listing_stock_transactions_smart_listing][:sort].keys.first.eql?("transaction_date")
        "#{params[:listing_stock_transactions_smart_listing][:sort].keys.first} #{params[:listing_stock_transactions_smart_listing][:sort][params[:listing_stock_transactions_smart_listing][:sort].keys.first]}, transaction_number ASC, transaction_type ASC, products.code ASC, common_fields.code ASC, size ASC, product_first_price ASC, quantity ASC, total_product_price ASC"
      elsif params[:listing_stock_transactions_smart_listing][:sort].keys.first.eql?("transaction_number")
        "#{params[:listing_stock_transactions_smart_listing][:sort].keys.first} #{params[:listing_stock_transactions_smart_listing][:sort][params[:listing_stock_transactions_smart_listing][:sort].keys.first]}, transaction_type ASC, products.code ASC, common_fields.code ASC, size ASC, product_first_price ASC, quantity ASC, total_product_price ASC"
      elsif params[:listing_stock_transactions_smart_listing][:sort].keys.first.eql?("transaction_type")
        "#{params[:listing_stock_transactions_smart_listing][:sort].keys.first} #{params[:listing_stock_transactions_smart_listing][:sort][params[:listing_stock_transactions_smart_listing][:sort].keys.first]}, products.code ASC, common_fields.code ASC, size ASC, product_first_price ASC, quantity ASC, total_product_price ASC"
      elsif params[:listing_stock_transactions_smart_listing][:sort].keys.first.eql?("products.code")
        "#{params[:listing_stock_transactions_smart_listing][:sort].keys.first} #{params[:listing_stock_transactions_smart_listing][:sort][params[:listing_stock_transactions_smart_listing][:sort].keys.first]}, common_fields.code ASC, size ASC, product_first_price ASC, quantity ASC, total_product_price ASC"
      elsif params[:listing_stock_transactions_smart_listing][:sort].keys.first.eql?("common_fields.code")
        "#{params[:listing_stock_transactions_smart_listing][:sort].keys.first} #{params[:listing_stock_transactions_smart_listing][:sort][params[:listing_stock_transactions_smart_listing][:sort].keys.first]}, size ASC, product_first_price ASC, quantity ASC, total_product_price ASC"
      elsif params[:listing_stock_transactions_smart_listing][:sort].keys.first.eql?("size")
        "#{params[:listing_stock_transactions_smart_listing][:sort].keys.first} #{params[:listing_stock_transactions_smart_listing][:sort][params[:listing_stock_transactions_smart_listing][:sort].keys.first]}, product_first_price ASC, quantity ASC, total_product_price ASC"
      elsif params[:listing_stock_transactions_smart_listing][:sort].keys.first.eql?("product_first_price")
        "#{params[:listing_stock_transactions_smart_listing][:sort].keys.first} #{params[:listing_stock_transactions_smart_listing][:sort][params[:listing_stock_transactions_smart_listing][:sort].keys.first]}, quantity ASC, total_product_price ASC"
      elsif params[:listing_stock_transactions_smart_listing][:sort].keys.first.eql?("quantity")
        "#{params[:listing_stock_transactions_smart_listing][:sort].keys.first} #{params[:listing_stock_transactions_smart_listing][:sort][params[:listing_stock_transactions_smart_listing][:sort].keys.first]}, total_product_price ASC"
      elsif params[:listing_stock_transactions_smart_listing][:sort].keys.first.eql?("total_product_price")
        "#{params[:listing_stock_transactions_smart_listing][:sort].keys.first} #{params[:listing_stock_transactions_smart_listing][:sort][params[:listing_stock_transactions_smart_listing][:sort].keys.first]}"
      end
      listing_stock_transactions_scope.order(order_fields)
    else
      listing_stock_transactions_scope.order("transaction_date ASC, transaction_number ASC, transaction_type ASC, products.code ASC, common_fields.code ASC, size ASC, product_first_price ASC, quantity ASC, total_product_price ASC")
    end

    smart_listing_create(:listing_stock_transactions, listing_stock_transactions_scope, partial: 'listing_stocks/listing', paginate: false, sort: {transaction_date: "ASC"})
  end

  # GET /listing_stocks/1
  # GET /listing_stocks/1.json
  def show
  end

  # GET /listing_stocks/new
  def new
    @listing_stock = ListingStock.new
  end

  # GET /listing_stocks/1/edit
  def edit
  end

  # POST /listing_stocks
  # POST /listing_stocks.json
  def create
    @listing_stock = ListingStock.new(listing_stock_params)

    respond_to do |format|
      if @listing_stock.save
        format.html { redirect_to @listing_stock, notice: 'Listing stock was successfully created.' }
        format.json { render :show, status: :created, location: @listing_stock }
      else
        format.html { render :new }
        format.json { render json: @listing_stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /listing_stocks/1
  # PATCH/PUT /listing_stocks/1.json
  def update
    respond_to do |format|
      if @listing_stock.update(listing_stock_params)
        format.html { redirect_to @listing_stock, notice: 'Listing stock was successfully updated.' }
        format.json { render :show, status: :ok, location: @listing_stock }
      else
        format.html { render :edit }
        format.json { render json: @listing_stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /listing_stocks/1
  # DELETE /listing_stocks/1.json
  def destroy
    @listing_stock.destroy
    respond_to do |format|
      format.html { redirect_to listing_stocks_url, notice: 'Listing stock was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def print
    @listing_stock_transactions_scope = if params[:filter_warehouse].present?
      splitted_date = params[:filter_listing_transaction_date].split(" - ")
      ListingStockTransaction.
        joins(listing_stock_product_detail: [:color, :size, listing_stock: [:warehouse, product: :brand]]).
        select(:transaction_date, :transaction_number, :transaction_type, :quantity).
        select("products.code AS product_code, brands_products.name AS product_name, common_fields.code AS color_code, common_fields.name AS color_name, size, warehouses.warehouse_type").
        select("(SELECT price_lists.price FROM price_lists INNER JOIN product_details ON product_details.id = price_lists.product_detail_id WHERE (product_details.size_id = listing_stock_product_details.size_id AND product_details.product_id = listing_stocks.product_id AND product_details.price_code_id = warehouses.price_code_id) ORDER BY price_lists.effective_date ASC LIMIT 1) AS product_first_price").
        select("((SELECT price_lists.price FROM price_lists INNER JOIN product_details ON product_details.id = price_lists.product_detail_id WHERE (product_details.size_id = listing_stock_product_details.size_id AND product_details.product_id = listing_stocks.product_id AND product_details.price_code_id = warehouses.price_code_id) ORDER BY price_lists.effective_date ASC LIMIT 1) * listing_stock_transactions.quantity) AS total_product_price").
        where(["transaction_date BETWEEN ? AND ? AND warehouse_id = ? AND warehouses.is_active = ?", splitted_date[0].to_date, splitted_date[1].to_date, params[:filter_warehouse], true]).order("transaction_date")
    else
      ListingStockTransaction.none
    end
    @start_date = splitted_date[0].to_date
    @end_date = splitted_date[1].to_date
    @warehouse =Warehouse.find(params[:filter_warehouse])
    p @listing_stock_transactions_scope
    respond_to do |format|
      format.js
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_listing_stock
    @listing_stock = ListingStock.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def listing_stock_params
    params.require(:listing_stock).permit(:warehouse_id, :product_id)
  end
end
