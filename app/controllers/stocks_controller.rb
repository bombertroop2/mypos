include SmartListing::Helper::ControllerExtensions
class StocksController < ApplicationController
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
    stocks_scope = StockDetail.joins(:size, :color, stock_product: [{product: :brand}, {stock: :warehouse}]).select("warehouses.name, products.code, brands_products.name AS brand_name, common_fields.name AS color_name, size AS size_label, quantity")
    stocks_scope = stocks_scope.where(["warehouses.name #{like_command} ?", "%"+params[:filter]+"%"]).
      or(stocks_scope.where(["products.code #{like_command} ?", "%"+params[:filter]+"%"])).
      or(stocks_scope.where(["brands_products.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(stocks_scope.where(["common_fields.name #{like_command} ?", "%"+params[:filter]+"%"])).
      or(stocks_scope.where(["size #{like_command} ?", "%"+params[:filter]+"%"])).
      or(stocks_scope.where(["quantity #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @stocks = smart_listing_create(:stocks, stocks_scope, partial: 'stocks/listing', default_sort: {:"warehouses.name" => "asc"})

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
