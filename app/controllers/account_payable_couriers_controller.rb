include SmartListing::Helper::ControllerExtensions
class AccountPayableCouriersController < ApplicationController
  authorize_resource except: :overdue_invoice_list
  before_action :set_account_payable_courier, only: :destroy
  helper SmartListing::Helper

  # GET /account_payable_couriers
  # GET /account_payable_couriers.json
  def index
    if params[:filter_ap_invoice_courier_courier_invoice_date].present?
      splitted_date_range = params[:filter_ap_invoice_courier_courier_invoice_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end
    
    if params[:filter_ap_invoice_courier_due_date].present?
      splitted_due_date_range = params[:filter_ap_invoice_courier_due_date].split("-")
      start_due_date = splitted_due_date_range[0].strip.to_date
      end_due_date = splitted_due_date_range[1].strip.to_date
    end

    if params[:filter_ap_invoice_courier_status].present?
      remaining_debt_query = if params[:filter_ap_invoice_courier_status].eql?("All")
        "remaining_debt >= 0"
      elsif params[:filter_ap_invoice_courier_status].eql?("Paid off")
        "remaining_debt = 0"
      else
        "remaining_debt > 0"
      end
    end

    account_payable_couriers_scope = AccountPayableCourier.select(:id, :number, "couriers.code AS courier_code", "couriers.name AS courier_name", :total, :remaining_debt, :courier_invoice_number, :courier_invoice_date, :due_date).joins(:courier)
    account_payable_couriers_scope = account_payable_couriers_scope.where(["number ILIKE ? OR courier_invoice_number ILIKE ?", "%"+params[:filter_ap_invoice_courier_invoice_number]+"%", "%"+params[:filter_ap_invoice_courier_invoice_number]+"%"]) if params[:filter_ap_invoice_courier_invoice_number].present?
    account_payable_couriers_scope = account_payable_couriers_scope.where(["courier_id = ?", params[:filter_ap_invoice_courier_courier_id]]) if params[:filter_ap_invoice_courier_courier_id].present?
    account_payable_couriers_scope = account_payable_couriers_scope.where(["courier_invoice_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_ap_invoice_courier_courier_invoice_date].present?
    account_payable_couriers_scope = account_payable_couriers_scope.where(["due_date BETWEEN ? AND ?", start_due_date, end_due_date]) if params[:filter_ap_invoice_courier_due_date].present?
    account_payable_couriers_scope = account_payable_couriers_scope.where(remaining_debt_query) if params[:filter_ap_invoice_courier_status].present?
    smart_listing_create(:account_payable_couriers, account_payable_couriers_scope, partial: 'account_payable_couriers/listing', default_sort: {due_date: "asc"})
  end

  # GET /account_payable_couriers/1
  # GET /account_payable_couriers/1.json
  def show
    @account_payable_courier = AccountPayableCourier.
      select(:id, :number, :note, :total, :remaining_debt, :courier_invoice_number, :courier_invoice_date, :due_date, "couriers.code AS courier_code", "couriers.name AS courier_name", "couriers.value_added_tax_type AS courier_vat_type").
      joins(:courier).
      find(params[:id])
  end

  # GET /account_payable_couriers/new
  def new
    @account_payable_courier = AccountPayableCourier.new
  end

  # GET /account_payable_couriers/1/edit
  def edit
  end

  # POST /account_payable_couriers
  # POST /account_payable_couriers.json
  def create
    add_additional_params_to_child
    @account_payable_courier = AccountPayableCourier.new(account_payable_courier_params)
    recreate = false
    recreate_counter = 1
    begin
      begin
        recreate = false
        unless @created = @account_payable_courier.save          
          if @account_payable_courier.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@account_payable_courier.errors[:base].join("<br/>")}\",size: 'small'});"
          end
        end
      rescue ActiveRecord::RecordNotUnique => e
        if recreate_counter < 5
          recreate = true
          recreate_counter += 1
        else
          recreate = false
          render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
        end
      end
    end while recreate
  end

  # PATCH/PUT /account_payable_couriers/1
  # PATCH/PUT /account_payable_couriers/1.json
  def update
    respond_to do |format|
      if @account_payable_courier.update(account_payable_courier_params)
        format.html { redirect_to @account_payable_courier, notice: 'Account payable courier was successfully updated.' }
        format.json { render :show, status: :ok, location: @account_payable_courier }
      else
        format.html { render :edit }
        format.json { render json: @account_payable_courier.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account_payable_couriers/1
  # DELETE /account_payable_couriers/1.json
  def destroy
    @deleted = @account_payable_courier.destroy
  end
  
  def get_packing_lists
    @packing_lists = PackingList.
      select(:id, :number, :departure_date, :total_volume, :total_weight, "courier_prices.price AS courier_prc", "couriers.value_added_tax_type AS courier_vat_type").
      joins(packing_list_items: :shipment, courier_price: [courier_unit: [courier_way: :courier]]).
      where(["packing_lists.account_payable_courier_id IS NULL AND packing_lists.departure_date <= ? AND couriers.id = ? AND couriers.status = 'External' AND shipments.received_date IS NOT NULL", params[:courier_invoice_date].to_date, params[:courier_id]]).
      distinct
    render partial: 'packing_lists'
  end
  
  def print
    @account_payable_courier = AccountPayableCourier.
      select(:id, :number, :note, :total, :remaining_debt, :courier_invoice_number, :courier_invoice_date, :courier_id, :due_date, "couriers.code AS courier_code", "couriers.name AS courier_name", "couriers.value_added_tax_type AS courier_vat_type").
      joins(:courier).
      find(params[:id])
  end
  
  def overdue_invoice_list
    authorize! :read, AccountPayableCourier
    if params[:filter_ap_invoice_courier_courier_invoice_date].present?
      splitted_date_range = params[:filter_ap_invoice_courier_courier_invoice_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end
    
    if params[:filter_ap_invoice_courier_due_date].present?
      splitted_due_date_range = params[:filter_ap_invoice_courier_due_date].split("-")
      start_due_date = splitted_due_date_range[0].strip.to_date
      end_due_date = splitted_due_date_range[1].strip.to_date
    end

    account_payable_couriers_scope = AccountPayableCourier.select(:id, :number, "couriers.code AS courier_code", "couriers.name AS courier_name", :total, :remaining_debt, :courier_invoice_number, :courier_invoice_date, :due_date).joins(:courier).where("remaining_debt > 0").where(["account_payable_couriers.due_date < ?", Date.current])
    account_payable_couriers_scope = account_payable_couriers_scope.where(["number ILIKE ? OR courier_invoice_number ILIKE ?", "%"+params[:filter_ap_invoice_courier_invoice_number]+"%", "%"+params[:filter_ap_invoice_courier_invoice_number]+"%"]) if params[:filter_ap_invoice_courier_invoice_number].present?
    account_payable_couriers_scope = account_payable_couriers_scope.where(["courier_id = ?", params[:filter_ap_invoice_courier_courier_id]]) if params[:filter_ap_invoice_courier_courier_id].present?
    account_payable_couriers_scope = account_payable_couriers_scope.where(["courier_invoice_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_ap_invoice_courier_courier_invoice_date].present?
    account_payable_couriers_scope = account_payable_couriers_scope.where(["due_date BETWEEN ? AND ?", start_due_date, end_due_date]) if params[:filter_ap_invoice_courier_due_date].present?
    smart_listing_create(:account_payable_couriers, account_payable_couriers_scope, partial: 'account_payable_couriers/listing', default_sort: {due_date: "asc"})
  end

  private
  
  def add_additional_params_to_child
    params[:account_payable_courier][:packing_lists_attributes].each do |key, value|
      params[:account_payable_courier][:packing_lists_attributes][key][:attr_creating_ap_invoice] = true
    end if params[:account_payable_courier][:packing_lists_attributes].present?
  end
  
  # Use callbacks to share common setup or constraints between actions.
  def set_account_payable_courier
    @account_payable_courier = AccountPayableCourier.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_payable_courier_params
    params.require(:account_payable_courier).permit(:number, :courier_id, :note, :total, :remaining_debt, :courier_invoice_number, :courier_invoice_date,
      packing_lists_attributes: [:id, :attr_creating_ap_invoice])
  end
end
