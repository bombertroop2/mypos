include SmartListing::Helper::ControllerExtensions
class AccountsReceivablePaymentsController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  #  before_action :set_accounts_receivable_payment, only: [:show, :edit, :update, :destroy]

  # GET /accounts_receivable_payments
  # GET /accounts_receivable_payments.json
  def index
    if params[:filter_ar_payment_date].present?
      splitted_date_range = params[:filter_ar_payment_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end

    accounts_receivable_payments_scope = AccountsReceivablePayment.joins(:customer).select(:id, :payment_date, :amount, :payment_method, :number, "customers.code AS customer_code", "customers.name AS customer_name")
    accounts_receivable_payments_scope = accounts_receivable_payments_scope.where(["payment_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_ar_payment_date].present?
    accounts_receivable_payments_scope = accounts_receivable_payments_scope.where(["payment_method = ?", params[:filter_ar_payment_method]]) if params[:filter_ar_payment_method].present?
    accounts_receivable_payments_scope = accounts_receivable_payments_scope.where(["number ILIKE ?", "%"+params[:filter_ar_payment_number]+"%"]) if params[:filter_ar_payment_number].present?
    accounts_receivable_payments_scope = accounts_receivable_payments_scope.where(["customers.id = ?", params[:filter_ar_payment_customer_id]]) if params[:filter_ar_payment_customer_id].present?
    smart_listing_create(:accounts_receivable_payments, accounts_receivable_payments_scope, partial: 'accounts_receivable_payments/listing', default_sort: {number: "asc"})
  end

  # GET /accounts_receivable_payments/1
  # GET /accounts_receivable_payments/1.json
  def show
    @accounts_receivable_payment = AccountsReceivablePayment.
      select(:id, :number, :payment_date, :payment_method, :giro_number, :giro_date, :created_at, :amount, "customers.code AS customer_code", "customers.name AS customer_name", "company_banks.code AS company_bank_code", "company_banks.name AS company_bank_name", "company_bank_account_numbers.account_number AS bank_account_number").
      joins(:customer).
      joins("LEFT JOIN company_bank_account_numbers ON accounts_receivable_payments.company_bank_account_number_id = company_bank_account_numbers.id").
      joins("LEFT JOIN company_banks ON company_bank_account_numbers.company_bank_id = company_banks.id").
      find(params[:id])
  end

  # GET /accounts_receivable_payments/new
  def new
  end

  # GET /accounts_receivable_payments/1/edit
  #  def edit
  #  end

  # POST /accounts_receivable_payments
  # POST /accounts_receivable_payments.json
  def create
    add_additional_params_to_child
    convert_amount_value
    calculate_total_amount
    @accounts_receivable_payment = AccountsReceivablePayment.new(accounts_receivable_payment_params)
    recreate = false
    recreate_counter = 1
    begin
      begin
        recreate = false
        unless @created = @accounts_receivable_payment.save
          if @accounts_receivable_payment.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@accounts_receivable_payment.errors[:base].join("<br/>")}\",size: 'small'});"
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

  # PATCH/PUT /accounts_receivable_payments/1
  # PATCH/PUT /accounts_receivable_payments/1.json
  #  def update
  #    respond_to do |format|
  #      if @accounts_receivable_payment.update(accounts_receivable_payment_params)
  #        format.html { redirect_to @accounts_receivable_payment, notice: 'Accounts receivable payment was successfully updated.' }
  #        format.json { render :show, status: :ok, location: @accounts_receivable_payment }
  #      else
  #        format.html { render :edit }
  #        format.json { render json: @accounts_receivable_payment.errors, status: :unprocessable_entity }
  #      end
  #    end
  #  end

  # DELETE /accounts_receivable_payments/1
  # DELETE /accounts_receivable_payments/1.json
  #  def destroy
  #    @accounts_receivable_payment.destroy
  #    respond_to do |format|
  #      format.html { redirect_to accounts_receivable_payments_url, notice: 'Accounts receivable payment was successfully destroyed.' }
  #      format.json { head :no_content }
  #    end
  #  end
  
  def generate_form
    @accounts_receivable_payment = AccountsReceivablePayment.new
    payment_method = if params[:tab].eql?("transfer")
      "Transfer"
    elsif params[:tab].eql?("giro")
      "Giro"
    else
      "Cash"
    end
    ar_invoices = AccountsReceivableInvoice.joins(shipment: [order_booking: :customer]).select(:id, :number, :remaining_debt, :total, "customers.code AS customer_code", "customers.name AS customer_name", "order_bookings.customer_id", "shipments.delivery_date AS shipment_delivery_date").where(id: params[:ar_invoice_ids].uniq).where("accounts_receivable_invoices.remaining_debt > 0").order(:number)
    ar_invoices.each do |ar_invoice|
      remaining_debt = ar_invoice.remaining_debt
      @accounts_receivable_payment.accounts_receivable_payment_invoices.build accounts_receivable_invoice_id: ar_invoice.id, attr_invoice_number: ar_invoice.number, attr_remaining_debt: remaining_debt, attr_amount_sold: ar_invoice.total, attr_invoice_date: ar_invoice.shipment_delivery_date
      @accounts_receivable_payment.customer_id = ar_invoice.customer_id
      @accounts_receivable_payment.attr_customer_code_and_name = "#{ar_invoice.customer_code} - #{ar_invoice.customer_name}"
    end
    render js: "bootbox.alert({message: \"Please choose one customer to make a payment\",size: 'small'});" if ar_invoices.pluck(:customer_id).uniq.length > 1
  end

  def get_account_numbers
    @account_numbers = CompanyBankAccountNumber.select(:id, :account_number).where(company_bank_id: params[:company_bank_id]).order(:account_number)
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_accounts_receivable_payment
    @accounts_receivable_payment = AccountsReceivablePayment.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def accounts_receivable_payment_params
    if params[:accounts_receivable_payment][:payment_method].eql?("Giro")
      params.require(:accounts_receivable_payment).permit(:payment_method, :customer_id, :attr_customer_code_and_name, :payment_date, :amount, :giro_number, :giro_date,
        accounts_receivable_payment_invoices_attributes: [:amount, :accounts_receivable_invoice_id, :attr_invoice_number, :attr_amount_sold, :attr_remaining_debt, :attr_payment_date, :attr_customer_id, :_destroy, :attr_invoice_date])
    elsif params[:accounts_receivable_payment][:payment_method].eql?("Transfer")
      params.require(:accounts_receivable_payment).permit(:payment_method, :customer_id, :attr_customer_code_and_name, :payment_date, :amount, :attr_company_bank_id, :company_bank_account_number_id,
        accounts_receivable_payment_invoices_attributes: [:amount, :accounts_receivable_invoice_id, :attr_invoice_number, :attr_amount_sold, :attr_remaining_debt, :attr_payment_date, :attr_customer_id, :_destroy, :attr_invoice_date])
    else
      params.require(:accounts_receivable_payment).permit(:payment_method, :customer_id, :attr_customer_code_and_name, :payment_date, :amount,
        accounts_receivable_payment_invoices_attributes: [:amount, :accounts_receivable_invoice_id, :attr_invoice_number, :attr_amount_sold, :attr_remaining_debt, :attr_payment_date, :attr_customer_id, :_destroy, :attr_invoice_date])
    end
  end
  
  def add_additional_params_to_child
    params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes].each do |key, value|
      params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes][key][:attr_payment_date] = params[:accounts_receivable_payment][:payment_date]
      params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes][key][:attr_customer_id] = params[:accounts_receivable_payment][:customer_id]
    end if params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes].present?
  end
  
  def convert_amount_value
    params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes].each do |key, value|
      params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes][key][:amount] = params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes][key][:amount].gsub("Rp","").gsub(".","").gsub(",",".") if params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes][key][:amount].present?
    end if params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes].present?
  end
  
  def calculate_total_amount
    total_amount = 0
    params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes].each do |key, value|
      if params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes][key][:_destroy].eql?("0")
        total_amount += params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes][key][:amount].to_f
      end
    end if params[:accounts_receivable_payment][:accounts_receivable_payment_invoices_attributes].present?
    params[:accounts_receivable_payment][:amount] = total_amount
  end
end
