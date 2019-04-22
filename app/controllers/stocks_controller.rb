include SmartListing::Helper::ControllerExtensions
class StocksController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_stock, only: [:show, :edit, :update, :destroy]

  # GET /stocks
  # GET /stocks.json
  def index
    like_command = "ILIKE"
    user_roles = current_user.roles.pluck :name
    stocks_scope = if user_roles.include?("area_manager")
      if params[:filter_warehouse_id].blank?
        @warehouses = current_user.supervisor.warehouses.select(:id, :code, :name).order(:code)
        Stock.none
      else
        @warehouse = Warehouse.select(:id, :price_code_id).find(params[:filter_warehouse_id])
        Stock.
          select(:id, "warehouses.name AS warehouse_name").
          joins(:warehouse, stock_products: [stock_details: [:size, :color], product: :brand]).
          where(warehouse_id: params[:filter_warehouse_id])
      end
    elsif user_roles.include?("staff") || user_roles.include?("manager") || user_roles.include?("administrator") || user_roles.include?("superadmin") || user_roles.include?("accountant")
      if params[:filter_warehouse_id].blank?
        @warehouses = Warehouse.select(:id, :code, :name).order(:code)
        Stock.none
      else
        @warehouse = Warehouse.select(:id, :price_code_id).find(params[:filter_warehouse_id])
        Stock.
          select(:id, "warehouses.name AS warehouse_name").
          joins(:warehouse, stock_products: [stock_details: [:size, :color], product: :brand]).
          where(warehouse_id: params[:filter_warehouse_id])
      end
    else
      if params[:filter_product_criteria]
        @warehouse = current_user.sales_promotion_girl.warehouse
        Stock.
          select(:id, "warehouses.name AS warehouse_name").
          joins(:warehouse, stock_products: [stock_details: [:size, :color], product: :brand]).
          where(warehouse_id: current_user.sales_promotion_girl.warehouse_id)
      else
        Stock.none
      end
    end
    smart_listing_create(:stocks, stocks_scope, partial: 'stocks/listing')
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
