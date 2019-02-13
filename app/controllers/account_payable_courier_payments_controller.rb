include SmartListing::Helper::ControllerExtensions
class AccountPayableCourierPaymentsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_account_payable_courier_payment, only: [:show, :print]

  # GET /account_payable_courier_payments
  # GET /account_payable_courier_payments.json
  def index
    if params[:filter_ap_courier_payment_date].present?
      splitted_date_range = params[:filter_ap_courier_payment_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end

    account_payable_courier_payments_scope = AccountPayableCourierPayment.joins(:courier).select(:id, :payment_date, :amount, :payment_method, :number, "couriers.code AS courier_code", "couriers.name AS courier_name")
    account_payable_courier_payments_scope = account_payable_courier_payments_scope.where(["payment_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_ap_courier_payment_date].present?
    account_payable_courier_payments_scope = account_payable_courier_payments_scope.where(["payment_method = ?", params[:filter_ap_courier_payment_method]]) if params[:filter_ap_courier_payment_method].present?
    account_payable_courier_payments_scope = account_payable_courier_payments_scope.where(["number ILIKE ?", "%"+params[:filter_ap_courier_payment_number]+"%"]) if params[:filter_ap_courier_payment_number].present?
    account_payable_courier_payments_scope = account_payable_courier_payments_scope.where(["couriers.id = ?", params[:filter_ap_courier_payment_courier_id]]) if params[:filter_ap_courier_payment_courier_id].present?
    smart_listing_create(:account_payable_courier_payments, account_payable_courier_payments_scope, partial: 'account_payable_courier_payments/listing', default_sort: {number: "asc"})
  end

  # GET /account_payable_courier_payments/1
  # GET /account_payable_courier_payments/1.json
  def show
  end

  # GET /account_payable_courier_payments/new
  def new
    @account_payable_courier_payment = AccountPayableCourierPayment.new
  end

  # GET /account_payable_courier_payments/1/edit
  def edit
  end

  # POST /account_payable_courier_payments
  # POST /account_payable_courier_payments.json
  def create
    add_additional_params_to_child
    convert_amount_value
    calculate_total_amount
    @account_payable_courier_payment = AccountPayableCourierPayment.new(account_payable_courier_payment_params)
    recreate = false
    recreate_counter = 1
    begin
      begin
        recreate = false
        unless @created = @account_payable_courier_payment.save
          if @account_payable_courier_payment.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@account_payable_courier_payment.errors[:base].join("<br/>")}\",size: 'small'});"
          end
        else
          SendEmailJob.perform_later(@account_payable_courier_payment, "account payable courier payment")
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

  # PATCH/PUT /account_payable_courier_payments/1
  # PATCH/PUT /account_payable_courier_payments/1.json
  def update
    respond_to do |format|
      if @account_payable_courier_payment.update(account_payable_courier_payment_params)
        format.html { redirect_to @account_payable_courier_payment, notice: 'Account payable courier payment was successfully updated.' }
        format.json { render :show, status: :ok, location: @account_payable_courier_payment }
      else
        format.html { render :edit }
        format.json { render json: @account_payable_courier_payment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account_payable_courier_payments/1
  # DELETE /account_payable_courier_payments/1.json
  def destroy
    @account_payable_courier_payment.destroy
    respond_to do |format|
      format.html { redirect_to account_payable_courier_payments_url, notice: 'Account payable courier payment was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def generate_form
    @account_payable_courier_payment = AccountPayableCourierPayment.new
    payment_method = if params[:tab].eql?("transfer")
      "Transfer"
    elsif params[:tab].eql?("giro")
      "Giro"
    else
      "Cash"
    end
    ap_invoices = AccountPayableCourier.joins(:courier).select(:id, :number, :remaining_debt, :total, :courier_invoice_number, :courier_invoice_date, :courier_id, "couriers.code AS courier_code", "couriers.name AS courier_name").where(id: params[:ap_invoice_ids].uniq).where("couriers.status = 'External' AND account_payable_couriers.remaining_debt > 0").order(:number)
    ap_invoices.each do |ap_invoice|
      remaining_debt = ap_invoice.remaining_debt
      @account_payable_courier_payment.account_payable_courier_payment_invoices.build account_payable_courier_id: ap_invoice.id, attr_invoice_number: ap_invoice.number, attr_remaining_debt: remaining_debt, attr_amount_invoiced: ap_invoice.total, attr_courier_invoice_number: ap_invoice.courier_invoice_number, attr_courier_invoice_date: ap_invoice.courier_invoice_date
      @account_payable_courier_payment.courier_id = ap_invoice.courier_id
      @account_payable_courier_payment.attr_courier_code_and_name = "#{ap_invoice.courier_code} - #{ap_invoice.courier_name}"
    end
    render js: "bootbox.alert({message: \"Please choose one courier to make a payment\",size: 'small'});" if ap_invoices.pluck(:courier_id).uniq.length > 1
  end
  
  def get_account_numbers
    @account_numbers = CompanyBankAccountNumber.select(:id, :account_number).where(company_bank_id: params[:company_bank_id]).order(:account_number)
  end
  
  def print
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_payable_courier_payment
    @account_payable_courier_payment = AccountPayableCourierPayment.
      select(:id, :payment_date, :amount, :payment_method, :number, :giro_number, :giro_date, :created_at, :courier_id, :company_bank_account_number_id, "couriers.code AS courier_code", "couriers.name AS courier_name", "company_banks.code AS bank_code", "company_banks.name AS bank_name", "company_bank_account_numbers.account_number AS bank_account_number").
      joins(:courier).
      joins("LEFT JOIN company_bank_account_numbers ON account_payable_courier_payments.company_bank_account_number_id = company_bank_account_numbers.id").
      joins("LEFT JOIN company_banks ON company_bank_account_numbers.company_bank_id = company_banks.id").
      find(params[:id])

  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_payable_courier_payment_params
    if params[:account_payable_courier_payment][:payment_method].eql?("Giro")
      params.require(:account_payable_courier_payment).permit(:payment_date, :amount, :payment_method, :giro_number, :giro_date, :courier_id, :attr_courier_code_and_name,
        account_payable_courier_payment_invoices_attributes: [:account_payable_courier_id, :attr_invoice_number, :attr_amount_invoiced, :attr_remaining_debt, :amount, :_destroy, :attr_payment_date, :attr_courier_invoice_number, :attr_courier_invoice_date, :attr_courier_id])
    elsif params[:account_payable_courier_payment][:payment_method].eql?("Cash")
      params.require(:account_payable_courier_payment).permit(:payment_date, :amount, :payment_method, :courier_id, :attr_courier_code_and_name,
        account_payable_courier_payment_invoices_attributes: [:account_payable_courier_id, :attr_invoice_number, :attr_amount_invoiced, :attr_remaining_debt, :amount, :_destroy, :attr_payment_date, :attr_courier_invoice_number, :attr_courier_invoice_date, :attr_courier_id])
    else
      params.require(:account_payable_courier_payment).permit(:payment_date, :amount, :payment_method, :courier_id, :attr_courier_code_and_name, :attr_company_bank_id, :company_bank_account_number_id,
        account_payable_courier_payment_invoices_attributes: [:account_payable_courier_id, :attr_invoice_number, :attr_amount_invoiced, :attr_remaining_debt, :amount, :_destroy, :attr_payment_date, :attr_courier_invoice_number, :attr_courier_invoice_date, :attr_courier_id])
    end
  end
  
  def add_additional_params_to_child
    params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes].each do |key, value|
      params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes][key][:attr_payment_date] = params[:account_payable_courier_payment][:payment_date]
      params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes][key][:attr_courier_id] = params[:account_payable_courier_payment][:courier_id]
    end if params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes].present?
  end
  
  def convert_amount_value
    params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes].each do |key, value|
      params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes][key][:amount] = params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes][key][:amount].gsub("Rp","").gsub(".","").gsub(",",".") if params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes][key][:amount].present?
    end if params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes].present?
  end
  
  def calculate_total_amount
    total_amount = 0
    params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes].each do |key, value|
      if params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes][key][:_destroy].eql?("0")
        total_amount += params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes][key][:amount].to_f
      end
    end if params[:account_payable_courier_payment][:account_payable_courier_payment_invoices_attributes].present?
    params[:account_payable_courier_payment][:amount] = total_amount
  end
end
