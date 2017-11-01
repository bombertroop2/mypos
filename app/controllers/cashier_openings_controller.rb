class CashierOpeningsController < ApplicationController
  load_and_authorize_resource
  before_action :set_cashier_opening, only: [:show, :edit, :update, :destroy]

  # GET /cashier_openings
  # GET /cashier_openings.json
  def index
    @cashier_openings = CashierOpening.all
  end

  # GET /cashier_openings/1
  # GET /cashier_openings/1.json
  def show
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
      if @cashier_opening.save
        render js: "bootbox.alert({message: 'Cashier was successfully opened', size: 'small'});"
      elsif @cashier_opening.errors[:base].present?
        render js: "bootbox.alert({message: \"#{@cashier_opening.errors[:base].join("<br/>")}\",size: 'small'});"
      end
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

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_cashier_opening
    @cashier_opening = CashierOpening.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def cashier_opening_params
    params.require(:cashier_opening).permit(:shift, :warehouse_id, :station, :beginning_cash)
  end
end
