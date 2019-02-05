include SmartListing::Helper::ControllerExtensions
class AccountPayablePaymentsController < ApplicationController
  include PurchaseReturnsHelper
  helper SmartListing::Helper
  authorize_resource
  before_action :set_account_payable_payment, only: [:show, :print]

  # GET /account_payable_payments
  # GET /account_payable_payments.json
  def index
    if params[:filter_ap_payment_date].present?
      splitted_date_range = params[:filter_ap_payment_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end

    account_payable_payments_scope = AccountPayablePayment.joins(:vendor).select(:id, :payment_date, :amount, :payment_method, :number, "vendors.code", "vendors.name").where(["vendors.is_active = ?", true])
    account_payable_payments_scope = account_payable_payments_scope.where(["payment_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_ap_payment_date].present?
    account_payable_payments_scope = account_payable_payments_scope.where(["payment_method = ?", params[:filter_ap_payment_method]]) if params[:filter_ap_payment_method].present?
    account_payable_payments_scope = account_payable_payments_scope.where(["number ILIKE ?", "%"+params[:filter_ap_payment_number]+"%"]) if params[:filter_ap_payment_number].present?
    account_payable_payments_scope = account_payable_payments_scope.where(["vendors.id = ?", params[:filter_ap_payment_vendor_id]]) if params[:filter_ap_payment_vendor_id].present?
    smart_listing_create(:account_payable_payments, account_payable_payments_scope, partial: 'account_payable_payments/listing', default_sort: {number: "asc"})
  end

  # GET /account_payable_payments/1
  # GET /account_payable_payments/1.json
  def show
  end

  # GET /account_payable_payments/new
  def new
  end

  # GET /account_payable_payments/1/edit
  def edit
  end

  # POST /account_payable_payments
  # POST /account_payable_payments.json
  def create
    add_additional_params_to_child
    convert_amount_value
    calculate_total_amount
    @account_payable_payment = AccountPayablePayment.new(account_payable_payment_params)
    recreate = false
    recreate_counter = 1
    begin
      begin
        recreate = false
        unless @created = @account_payable_payment.save
          if @account_payable_payment.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@account_payable_payment.errors[:base].join("<br/>")}\",size: 'small'});"
          end
        else
          SendEmailJob.perform_later(@account_payable_payment)
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

  # PATCH/PUT /account_payable_payments/1
  # PATCH/PUT /account_payable_payments/1.json
  def update
    respond_to do |format|
      if @account_payable_payment.update(account_payable_payment_params)
        format.html { redirect_to @account_payable_payment, notice: 'Account payable payment was successfully updated.' }
        format.json { render :show, status: :ok, location: @account_payable_payment }
      else
        format.html { render :edit }
        format.json { render json: @account_payable_payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account_payable_payments/1
  # DELETE /account_payable_payments/1.json
  def destroy
    @account_payable_payment.destroy
    respond_to do |format|
      format.html { redirect_to account_payable_payments_url, notice: 'Account payable payment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def generate_form
    @account_payable_payment = AccountPayablePayment.new
    payment_method = if params[:tab].eql?("transfer")
      "Transfer"
    elsif params[:tab].eql?("giro")
      "Giro"
    else
      "Cash"
    end
    ap_invoices = AccountPayable.joins(:vendor).select(:id, :number, :remaining_debt, :total, :vendor_invoice_number, :vendor_invoice_date, "vendors.code", "vendors.name", "vendors.id AS vendor_id").where(id: params[:ap_invoice_ids].uniq).where(["vendors.is_active = ? AND account_payables.remaining_debt > 0", true]).order(:number)
    ap_invoices.each do |ap_invoice|
      remaining_debt = ap_invoice.remaining_debt
      @account_payable_payment.account_payable_payment_invoices.build account_payable_id: ap_invoice.id, attr_invoice_number: ap_invoice.number, attr_remaining_debt: remaining_debt, attr_amount_received: ap_invoice.total, attr_vendor_invoice_number: ap_invoice.vendor_invoice_number, attr_vendor_invoice_date: ap_invoice.vendor_invoice_date
      @account_payable_payment.vendor_id = ap_invoice.vendor_id
      @account_payable_payment.attr_vendor_code_and_name = "#{ap_invoice.code} - #{ap_invoice.name}"
    end
    render js: "bootbox.alert({message: \"Please choose one vendor to make a payment\",size: 'small'});" if ap_invoices.pluck(:vendor_id).uniq.length > 1
  end
  
  def get_purchase_returns
    @purchase_returns = if params[:selected_purchase_return_ids].present?
      PurchaseReturn.
        where(["purchase_returns.id NOT IN (?) AND is_allocated = ? AND (vendors.id = ? OR vendors_direct_purchases.id = ?) AND (vendors.is_active = ? OR vendors_direct_purchases.is_active = ?)", params[:selected_purchase_return_ids].map{|id| id.to_i}, false, params[:vendor_id], params[:vendor_id], true, true]).
        joins("LEFT JOIN purchase_orders ON purchase_returns.purchase_order_id = purchase_orders.id").
        joins("LEFT JOIN vendors ON purchase_orders.vendor_id = vendors.id").
        joins("LEFT JOIN direct_purchases ON purchase_returns.direct_purchase_id = direct_purchases.id").
        joins("LEFT JOIN vendors vendors_direct_purchases ON direct_purchases.vendor_id = vendors_direct_purchases.id").
        select(:id, :number, :purchase_order_id, :direct_purchase_id)
    else
      PurchaseReturn.
        where(["is_allocated = ? AND (vendors.id = ? OR vendors_direct_purchases.id = ?) AND (vendors.is_active = ? OR vendors_direct_purchases.is_active = ?)", false, params[:vendor_id], params[:vendor_id], true, true]).
        joins("LEFT JOIN purchase_orders ON purchase_returns.purchase_order_id = purchase_orders.id").
        joins("LEFT JOIN vendors ON purchase_orders.vendor_id = vendors.id").
        joins("LEFT JOIN direct_purchases ON purchase_returns.direct_purchase_id = direct_purchases.id").
        joins("LEFT JOIN vendors vendors_direct_purchases ON direct_purchases.vendor_id = vendors_direct_purchases.id").
        select(:id, :number, :purchase_order_id, :direct_purchase_id)
    end
    render partial: 'show_return_items'
  end
  
  def select_purchase_return
    @total_amount_returned = 0
    @account_payable_payment = AccountPayablePayment.new
    @account_payable_payment_invoice = @account_payable_payment.account_payable_payment_invoices.build
    params[:purchase_return_ids].each do |purchase_return_id|
      purchase_return = PurchaseReturn.
        where(["purchase_returns.id = ? AND is_allocated = ? AND (vendors.id = ? OR vendors_direct_purchases.id = ?) AND (vendors.is_active = ? OR vendors_direct_purchases.is_active = ?)", purchase_return_id, false, params[:vendor_id], params[:vendor_id], true, true]).
        joins("LEFT JOIN purchase_orders ON purchase_returns.purchase_order_id = purchase_orders.id").
        joins("LEFT JOIN vendors ON purchase_orders.vendor_id = vendors.id").
        joins("LEFT JOIN direct_purchases ON purchase_returns.direct_purchase_id = direct_purchases.id").
        joins("LEFT JOIN vendors vendors_direct_purchases ON direct_purchases.vendor_id = vendors_direct_purchases.id").
        select("purchase_returns.id", :purchase_order_id, :direct_purchase_id).first
      @account_payable_payment_invoice.allocated_return_items.build purchase_return_id: purchase_return.id
      @total_amount_returned += value_after_ppn_pr(purchase_return)
    end
  end
  
  def print
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_payable_payment
    @account_payable_payment = AccountPayablePayment.
      select(:id, :payment_date, :amount, :payment_method, :number, :giro_number, :giro_date, :bank_account_number, :vendor_id, :bank_id, :created_at, "vendors.code", "vendors.name", "banks.code AS bank_code", "banks.name AS bank_name", "banks.card_type").
      joins(:vendor).
      joins("LEFT JOIN banks ON account_payable_payments.bank_id = banks.id").
      find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_payable_payment_params
    if params[:account_payable_payment][:payment_method].eql?("Giro")
      params.require(:account_payable_payment).permit(:payment_date, :amount, :vendor_id, :attr_vendor_code_and_name, :payment_method, :giro_number, :giro_date,
        account_payable_payment_invoices_attributes: [:account_payable_id, :attr_invoice_number, :attr_amount_received, :amount_returned, :attr_remaining_debt, :amount, :_destroy, :attr_payment_date, :attr_vendor_invoice_number, :attr_vendor_invoice_date, :attr_vendor_id,
          allocated_return_items_attributes: :purchase_return_id])
    elsif params[:account_payable_payment][:payment_method].eql?("Transfer")
      params.require(:account_payable_payment).permit(:payment_date, :amount, :vendor_id, :attr_vendor_code_and_name, :payment_method, :bank_id, :bank_account_number,
        account_payable_payment_invoices_attributes: [:account_payable_id, :attr_invoice_number, :attr_amount_received, :amount_returned, :attr_remaining_debt, :amount, :_destroy, :attr_payment_date, :attr_vendor_invoice_number, :attr_vendor_invoice_date, :attr_vendor_id,
          allocated_return_items_attributes: :purchase_return_id])
    else
      params.require(:account_payable_payment).permit(:payment_date, :amount, :vendor_id, :attr_vendor_code_and_name, :payment_method,
        account_payable_payment_invoices_attributes: [:account_payable_id, :attr_invoice_number, :attr_amount_received, :amount_returned, :attr_remaining_debt, :amount, :_destroy, :attr_payment_date, :attr_vendor_invoice_number, :attr_vendor_invoice_date, :attr_vendor_id,
          allocated_return_items_attributes: :purchase_return_id])
    end
  end
  
  def add_additional_params_to_child
    params[:account_payable_payment][:account_payable_payment_invoices_attributes].each do |key, value|
      params[:account_payable_payment][:account_payable_payment_invoices_attributes][key][:attr_payment_date] = params[:account_payable_payment][:payment_date]
      params[:account_payable_payment][:account_payable_payment_invoices_attributes][key][:attr_vendor_id] = params[:account_payable_payment][:vendor_id]
    end if params[:account_payable_payment][:account_payable_payment_invoices_attributes].present?
  end
  
  def convert_amount_value
    params[:account_payable_payment][:account_payable_payment_invoices_attributes].each do |key, value|
      params[:account_payable_payment][:account_payable_payment_invoices_attributes][key][:amount] = params[:account_payable_payment][:account_payable_payment_invoices_attributes][key][:amount].gsub("Rp","").gsub(".","").gsub(",",".") if params[:account_payable_payment][:account_payable_payment_invoices_attributes][key][:amount].present?
    end if params[:account_payable_payment][:account_payable_payment_invoices_attributes].present?
  end
  
  def calculate_total_amount
    total_amount = 0
    params[:account_payable_payment][:account_payable_payment_invoices_attributes].each do |key, value|
      if params[:account_payable_payment][:account_payable_payment_invoices_attributes][key][:_destroy].eql?("0")
        total_amount += params[:account_payable_payment][:account_payable_payment_invoices_attributes][key][:amount].to_f
      end
    end if params[:account_payable_payment][:account_payable_payment_invoices_attributes].present?
    params[:account_payable_payment][:amount] = total_amount
  end
end
