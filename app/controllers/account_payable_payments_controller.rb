include SmartListing::Helper::ControllerExtensions
class AccountPayablePaymentsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_account_payable_payment, only: [:show, :edit, :update, :destroy]

  # GET /account_payable_payments
  # GET /account_payable_payments.json
  def index
    if params[:filter_ap_payment_date].present?
      splitted_date_range = params[:filter_ap_payment_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end

    account_payable_payments_scope = AccountPayablePayment.select(:id, :payment_date, :amount)
    account_payable_payments_scope = account_payable_payments_scope.where(["payment_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_ap_payment_date].present?
    smart_listing_create(:account_payable_payments, account_payable_payments_scope, partial: 'account_payable_payments/listing', default_sort: {payment_date: "asc"})
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
    unless params[:account_payable_payment][:attr_payment_method].eql?("Giro")
      convert_amount_value
      calculate_total_amount
    end
    @account_payable_payment = AccountPayablePayment.new(account_payable_payment_params)
    unless @created = @account_payable_payment.save
      if @account_payable_payment.errors[:base].present?
        render js: "bootbox.alert({message: \"#{@account_payable_payment.errors[:base].join("<br/>")}\",size: 'small'});"
      end
    end
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
    ap_invoices = AccountPayable.joins(:vendor).select(:id, :number, :amount_returned, :payment_date, :remaining_debt, :total, "vendors.code", "vendors.name").where(id: params[:ap_invoice_ids], payment_method: payment_method).where(["vendors.is_active = ? AND account_payables.remaining_debt > 0", true]).order(:number)
    ap_invoices.each do |ap_invoice|
      remaining_debt = if ap_invoice.total == ap_invoice.remaining_debt
        ap_invoice.total - ap_invoice.amount_returned
      else
        ap_invoice.remaining_debt
      end
      @account_payable_payment.account_payable_payment_invoices.build account_payable_id: ap_invoice.id, attr_vendor_code_and_name: "#{ap_invoice.code} - #{ap_invoice.name}", attr_invoice_number: ap_invoice.number, attr_amount_returned: ap_invoice.amount_returned, attr_invoice_payment_date: ap_invoice.payment_date, attr_remaining_debt: remaining_debt, attr_amount_received: ap_invoice.total
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_payable_payment
    @account_payable_payment = AccountPayablePayment.select(:id, :payment_date, :amount).find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_payable_payment_params
    if params[:account_payable_payment][:attr_payment_method].eql?("Giro")
      params.require(:account_payable_payment).permit(:payment_date, :attr_payment_method,
        account_payable_payment_invoices_attributes: [:account_payable_id, :attr_vendor_code_and_name, :attr_invoice_number, :attr_invoice_payment_date, :attr_amount_received, :attr_amount_returned, :attr_remaining_debt, :_destroy, :attr_payment_date, :attr_payment_method])
    else
      params.require(:account_payable_payment).permit(:payment_date, :amount, :attr_payment_method,
        account_payable_payment_invoices_attributes: [:account_payable_id, :attr_vendor_code_and_name, :attr_invoice_number, :attr_invoice_payment_date, :attr_amount_received, :attr_amount_returned, :attr_remaining_debt, :amount, :_destroy, :attr_payment_date, :attr_payment_method])
    end
  end
  
  def add_additional_params_to_child
    params[:account_payable_payment][:account_payable_payment_invoices_attributes].each do |key, value|
      params[:account_payable_payment][:account_payable_payment_invoices_attributes][key].merge! attr_payment_date: params[:account_payable_payment][:payment_date]
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
