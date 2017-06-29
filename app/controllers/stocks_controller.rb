include SmartListing::Helper::ControllerExtensions
class StocksController < ApplicationController
  load_and_authorize_resource
  helper SmartListing::Helper
  before_action :set_stock, only: [:show, :edit, :update, :destroy]

  # GET /stocks
  # GET /stocks.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    stocks_scope = if current_user.has_non_spg_role?
      StockDetail.joins(:size, :color, stock_product: [{product: :brand}, {stock: :warehouse}]).select("warehouses.name, products.code, brands_products.name AS brand_name, common_fields.name AS color_name, size AS size_label, quantity")
    else
      StockDetail.joins(:size, :color, stock_product: [{product: :brand}, {stock: :warehouse}]).select("warehouses.name, products.code, brands_products.name AS brand_name, common_fields.name AS color_name, size AS size_label, quantity").where("warehouses.id = #{current_user.sales_promotion_girl.warehouse_id}")
    end
    stocks_scope = stocks_scope.where(["warehouses.id = ?", params[:filter_warehouse_id]]) if params[:filter_warehouse_id].present?
    stocks_scope = stocks_scope.where(["products.code #{like_command} ?", "%"+params[:filter_product_criteria]+"%"]).
      or(stocks_scope.where(["brands_products.name #{like_command} ?", "%"+params[:filter_product_criteria]+"%"])).
      or(stocks_scope.where(["common_fields.name #{like_command} ?", "%"+params[:filter_product_criteria]+"%"])).
      or(stocks_scope.where(["size #{like_command} ?", "%"+params[:filter_product_criteria]+"%"])).
      or(stocks_scope.where(["quantity #{like_command} ?", "%"+params[:filter_product_criteria]+"%"])) if params[:filter_product_criteria].present?
    stocks_scope = if params[:stocks_smart_listing].present? && params[:stocks_smart_listing][:sort].present?
      stocks_scope.order("#{params[:stocks_smart_listing][:sort].keys.first} #{params[:stocks_smart_listing][:sort][params[:stocks_smart_listing][:sort].keys.first]}")
    else
      stocks_scope.order("warehouses.name ASC")
    end

    stocks = []
    stock_hash = Hash.new    
    stocks_scope.each_with_index do |stock, index|
      if index == 0 && stocks_scope.length < 2
        stock_hash[stock.name] = {"#{stock.code} - #{stock.brand_name}" => {"code" => stock.code, stock.color_name => {stock.size_label => stock.quantity}}}
        stocks << stock_hash
      elsif index == 0
        stock_hash[stock.name] = {"#{stock.code} - #{stock.brand_name}" => {"code" => stock.code, stock.color_name => {stock.size_label => stock.quantity}}}
      else
        warehouses_hash_keys = stock_hash.keys
        if warehouses_hash_keys.include?(stock.name)
          products_hash_keys = stock_hash[stock.name].keys
          if products_hash_keys.include?("#{stock.code} - #{stock.brand_name}")
            colors_hash_keys = stock_hash[stock.name]["#{stock.code} - #{stock.brand_name}"].keys
            if colors_hash_keys.include?(stock.color_name)
              stock_hash[stock.name]["#{stock.code} - #{stock.brand_name}"][stock.color_name].merge!({stock.size_label => stock.quantity})
            else
              stock_hash[stock.name]["#{stock.code} - #{stock.brand_name}"].merge!({stock.color_name => {stock.size_label => stock.quantity}})
            end
          else
            stock_hash[stock.name].merge!({"#{stock.code} - #{stock.brand_name}" => {"code" => stock.code, stock.color_name => {stock.size_label => stock.quantity}}})
          end
          if index == stocks_scope.length - 1
            stock_hash.each do |key, val|
              stock_hash[key] = stock_hash[key].sort.to_h
            end
            stocks << stock_hash
          end
        else
          stock_hash.each do |key, val|
            stock_hash[key] = stock_hash[key].sort.to_h
          end
          stocks << stock_hash
          stock_hash = Hash.new    
          stock_hash[stock.name] = {"#{stock.code} - #{stock.brand_name}" => {"code" => stock.code, stock.color_name => {stock.size_label => stock.quantity}}}
          if index == stocks_scope.length - 1
            stocks << stock_hash
          end
        end
      end
    end

    stocks = stocks.reverse if params[:stocks_smart_listing].present? && params[:stocks_smart_listing][:sort].present?
    @warehouses = current_user.has_non_spg_role? ? Warehouse.select(:id, :code).order(:code) : []
    @stocks = smart_listing_create(:stocks, stocks, partial: 'stocks/listing', array: true)
  end

  # GET /stocks/1
  # GET /stocks/1.json
  def show
  end

  # GET /stocks/new
  def new
    @stock = Stock.new
  end

  # GET /stocks/1/edit
  def edit
  end

  # POST /stocks
  # POST /stocks.json
  def create
    @stock = Stock.new(stock_params)

    respond_to do |format|
      if @stock.save
        format.html { redirect_to @stock, notice: 'Stock was successfully created.' }
        format.json { render :show, status: :created, location: @stock }
      else
        format.html { render :new }
        format.json { render json: @stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /stocks/1
  # PATCH/PUT /stocks/1.json
  def update
    respond_to do |format|
      if @stock.update(stock_params)
        format.html { redirect_to @stock, notice: 'Stock was successfully updated.' }
        format.json { render :show, status: :ok, location: @stock }
      else
        format.html { render :edit }
        format.json { render json: @stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /stocks/1
  # DELETE /stocks/1.json
  def destroy
    @stock.destroy
    respond_to do |format|
      format.html { redirect_to stocks_url, notice: 'Stock was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_stock
    @stock = Stock.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def stock_params
    params[:stock]
  end
end
