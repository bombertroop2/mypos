include SmartListing::Helper::ControllerExtensions
class CashDisbursementsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_cash_disbursement, only: [:show, :edit, :update, :destroy]

  # GET /cash_disbursements
  # GET /cash_disbursements.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_date].present?
      splitted_date_range = params[:filter_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end
    warehouse_id = SalesPromotionGirl.select(:warehouse_id).where(id: current_user.sales_promotion_girl_id).first.warehouse_id
    cash_disbursements_scope = CashDisbursement.joins(cashier_opening: :warehouse).select(:id, :description, :price, :station, :open_date).where("opened_by = #{current_user.id} AND warehouse_id = #{warehouse_id}").where(["warehouses.is_active = ?", true])
    cash_disbursements_scope = cash_disbursements_scope.where(["description #{like_command} ?", "%"+params[:filter_string]+"%"]) if params[:filter_string].present?
    cash_disbursements_scope = cash_disbursements_scope.where(["DATE(open_date) BETWEEN ? AND ?", start_date, end_date]) if params[:filter_date].present?
    cash_disbursements_scope = cash_disbursements_scope.where(["station = ?", params[:filter_station]]) if params[:filter_station].present?
    @cash_disbursements = smart_listing_create(:cash_disbursements, cash_disbursements_scope, partial: 'cash_disbursements/listing', default_sort: {open_date: "asc"})
  end

  # GET /cash_disbursements/1
  # GET /cash_disbursements/1.json
  def show
  end

  # GET /cash_disbursements/new
  def new
    @cash_disbursement = CashDisbursement.new
  end

  # GET /cash_disbursements/1/edit
  def edit
  end

  # POST /cash_disbursements
  # POST /cash_disbursements.json
  def create
    params[:cash_disbursement][:price] = params[:cash_disbursement][:price].gsub("Rp","").gsub(".","").gsub(",",".") if params[:cash_disbursement][:price].present?
    @cash_disbursement = CashDisbursement.new(cash_disbursement_params)
    @cash_disbursement.user_id = current_user.id
    
    if @valid = @cash_disbursement.save
      @my_cashier = CashierOpening.select(:station, :open_date).where(opened_by: current_user.id, open_date: Date.current).where("closed_at IS NULL").first
    elsif @cash_disbursement.errors[:base].present?
      render js: "bootbox.alert({message: \"#{@cash_disbursement.errors[:base].join("<br/>")}\",size: 'small'});"
    end
  end

  # PATCH/PUT /cash_disbursements/1
  # PATCH/PUT /cash_disbursements/1.json
  def update
    respond_to do |format|
      if @cash_disbursement.update(cash_disbursement_params)
        format.html { redirect_to @cash_disbursement, notice: 'Cash disbursement was successfully updated.' }
        format.json { render :show, status: :ok, location: @cash_disbursement }
      else
        format.html { render :edit }
        format.json { render json: @cash_disbursement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cash_disbursements/1
  # DELETE /cash_disbursements/1.json
  def destroy
    @cash_disbursement.destroy
    respond_to do |format|
      format.html { redirect_to cash_disbursements_url, notice: 'Cash disbursement was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_cash_disbursement
    @cash_disbursement = CashDisbursement.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def cash_disbursement_params
    params.require(:cash_disbursement).permit(:cashier_opening_id, :description, :price)
  end
end
