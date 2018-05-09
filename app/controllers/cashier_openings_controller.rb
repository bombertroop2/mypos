include SmartListing::Helper::ControllerExtensions
class CashierOpeningsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_cashier_opening, only: [:edit, :update, :destroy, :close]

  # GET /cashier_openings
  # GET /cashier_openings.json
  def index
    flash[:notice] = ""
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_opened_at].present?
      splitted_date_range = params[:filter_opened_at].split("-")
      start_date = splitted_date_range[0].strip.to_date.beginning_of_day
      end_date = splitted_date_range[1].strip.to_date.end_of_day
    end
    warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
    cashiers_scope = CashierOpening.joins(:warehouse).select(:id, :station, "cashier_openings.created_at", :shift, :closed_at).where("opened_by = #{current_user.id} AND warehouse_id = #{warehouse_id}").where(["warehouses.is_active = ?", true])
    cashiers_scope = cashiers_scope.where(["cashier_openings.created_at BETWEEN ? AND ?", start_date, end_date]) if params[:filter_opened_at].present?
    cashiers_scope = cashiers_scope.where(["station = ?", params[:filter_station]]) if params[:filter_station].present?
    cashiers_scope = cashiers_scope.where(["shift = ?", params[:filter_shift]]) if params[:filter_shift].present?
    @cashiers = smart_listing_create(:cashiers, cashiers_scope, partial: 'cashier_openings/listing', default_sort: {:"cashier_openings.created_at" => "DESC"})
  end

  # GET /cashier_openings/1
  # GET /cashier_openings/1.json
  def show
    @cashier_opening = CashierOpening.joins(:warehouse, user: :sales_promotion_girl).where(id: params[:id], :"warehouses.warehouse_type" => "showroom").where(["warehouses.is_active = ?", true]).
      select("sales_promotion_girls.name AS cashier_name, warehouses.code, warehouses.name, cashier_openings.id, cashier_openings.created_at, station, shift, beginning_cash, cash_balance, closed_at, net_sales, gross_sales, cash_payment, card_payment, debit_card_payment, credit_card_payment, total_quantity, total_gift_quantity").first
  end

  # GET /cashier_openings/new
  def new
    @cashier_opening = CashierOpening.new
  end

  # GET /cashier_openings/1/edit
  def edit
  end

  # POST /cashier_openings
  # POST /cashier_openings.json
  def create
    params[:cashier_opening][:beginning_cash] = params[:cashier_opening][:beginning_cash].gsub("Rp","").gsub(".","").gsub(",",".") if params[:cashier_opening][:beginning_cash].present?
    @cashier_opening = CashierOpening.new(cashier_opening_params)
    @cashier_opening.warehouse_id = current_user.sales_promotion_girl.warehouse_id
    @cashier_opening.opened_by = current_user.id

    begin
      @opened = @cashier_opening.save
    rescue Exception => e
      render js: "bootbox.alert({message: 'Sorry, you can open the cashier only once per day', size: 'small'});"
    end
  end

  # PATCH/PUT /cashier_openings/1
  # PATCH/PUT /cashier_openings/1.json
  def update
    respond_to do |format|
      if @cashier_opening.update(cashier_opening_params)
        format.html { redirect_to @cashier_opening, notice: 'Cashier opening was successfully updated.' }
        format.json { render :show, status: :ok, location: @cashier_opening }
      else
        format.html { render :edit }
        format.json { render json: @cashier_opening.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cashier_openings/1
  # DELETE /cashier_openings/1.json
  def destroy
    @cashier_opening.destroy
    respond_to do |format|
      format.html { redirect_to cashier_openings_url, notice: 'Cashier opening was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def close
    @cashier_opening.with_lock do
      if @valid = @cashier_opening.update(closed_at: Time.current, user_id: current_user.id, closing_cashier: true)      
        SendEmailJob.perform_later(@cashier_opening.id, "cash disbursement report and sales general summary")
        SendEmailJob.perform_later(@cashier_opening.id, "sales general summary")
      end
    end
    @cashier_opening = CashierOpening.joins(:warehouse, user: :sales_promotion_girl).where(id: params[:id], :"warehouses.warehouse_type" => "showroom").
      select("sales_promotion_girls.name AS cashier_name, warehouses.code, warehouses.name, cashier_openings.id, cashier_openings.created_at, station, shift, beginning_cash, cash_balance, closed_at, net_sales, gross_sales, cash_payment, card_payment, debit_card_payment, credit_card_payment, total_quantity, total_gift_quantity, cashier_openings.warehouse_id, opened_by").first if @valid
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_cashier_opening
    @cashier_opening = CashierOpening.joins(:warehouse).select("cashier_openings.*").where(["warehouses.is_active = ?", true]).find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def cashier_opening_params
    params.require(:cashier_opening).permit(:shift, :warehouse_id, :station, :beginning_cash)
  end
end
