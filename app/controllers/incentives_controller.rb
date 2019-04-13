class IncentivesController < ApplicationController
  authorize_resource
  before_action :set_incentive, only: [:show, :edit, :update, :destroy]

  # GET /incentives
  # GET /incentives.json
  def index
    if params[:warehouse_code].present? || params[:incentive_spg].present? || params[:incentive_transaction_date].present? || params[:calculate_by].present?
      @warehouse = unless current_user.has_non_spg_role?
        Warehouse.select(:code).find(current_user.sales_promotion_girl.warehouse_id)
      else
        Warehouse.select(:code).find(params[:warehouse_code])
      end
      splitted_transaction_date = params[:incentive_transaction_date].split(" - ")
      @start_date = splitted_transaction_date[0].strip.to_date
      @end_date = splitted_transaction_date[1].strip.to_date
      @incentives = if params[:incentive_spg].strip.eql?("ALL")
        Incentive.
          select(:sales_promotion_girl_identifier, :sales_promotion_girl_name, "SUM(net_sales) AS total_net_sales", "SUM(quantity) AS total_quantity").
          where(["transaction_date BETWEEN ? AND ?", @start_date, @end_date]).
          group(:sales_promotion_girl_identifier, :sales_promotion_girl_name)
      else
        Incentive.
          select(:sales_promotion_girl_identifier, :sales_promotion_girl_name, "SUM(net_sales) AS total_net_sales", "SUM(quantity) AS total_quantity").
          where(["transaction_date BETWEEN ? AND ? AND sales_promotion_girl_name = ?", @start_date, @end_date, params[:incentive_spg]]).
          group(:sales_promotion_girl_identifier, :sales_promotion_girl_name)
      end
    end
  end

  # GET /incentives/1
  # GET /incentives/1.json
  def show
  end

  # GET /incentives/new
  def new
    @incentive = Incentive.new
  end

  # GET /incentives/1/edit
  def edit
  end

  # POST /incentives
  # POST /incentives.json
  def create
    @incentive = Incentive.new(incentive_params)

    respond_to do |format|
      if @incentive.save
        format.html { redirect_to @incentive, notice: 'Incentive was successfully created.' }
        format.json { render :show, status: :created, location: @incentive }
      else
        format.html { render :new }
        format.json { render json: @incentive.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /incentives/1
  # PATCH/PUT /incentives/1.json
  def update
    respond_to do |format|
      if @incentive.update(incentive_params)
        format.html { redirect_to @incentive, notice: 'Incentive was successfully updated.' }
        format.json { render :show, status: :ok, location: @incentive }
      else
        format.html { render :edit }
        format.json { render json: @incentive.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /incentives/1
  # DELETE /incentives/1.json
  def destroy
    @incentive.destroy
    respond_to do |format|
      format.html { redirect_to incentives_url, notice: 'Incentive was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_incentive
    @incentive = Incentive.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def incentive_params
    params.require(:incentive).permit(:warehouse_code, :warehouse_name, :transaction_date, :sales_promotion_girl_name, :transaction_number, :net_sales, :incentive, :quantity)
  end
end
