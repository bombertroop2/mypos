include SmartListing::Helper::ControllerExtensions
class AccountsReceivableInvoicesController < ApplicationController
  helper SmartListing::Helper
  authorize_resource
  before_action :set_accounts_receivable_invoice, only: :destroy

  # GET /accounts_receivable_invoices
  # GET /accounts_receivable_invoices.json
  def index
    if params[:filter_ar_invoice_due_date].present?
      splitted_date_range = params[:filter_ar_invoice_due_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end
    
    if params[:filter_ar_invoice_status].present?
      remaining_debt_query = if params[:filter_ar_invoice_status].eql?("All")
        "remaining_debt >= 0"
      elsif params[:filter_ar_invoice_status].eql?("Paid off")
        "remaining_debt = 0"
      else
        "remaining_debt > 0"
      end
    end

    accounts_receivable_invoices_scope = AccountsReceivableInvoice.select(:id, :number, :remaining_debt, :due_date, "shipments.delivery_order_number AS shipment_do_number", "customers.code AS customer_code", "customers.name AS customer_name").joins(shipment: [order_booking: :customer])
    accounts_receivable_invoices_scope = accounts_receivable_invoices_scope.where(["accounts_receivable_invoices.number ILIKE ? OR shipments.delivery_order_number ILIKE ?", "%"+params[:filter_ar_invoice_number]+"%", "%"+params[:filter_ar_invoice_number]+"%"]) if params[:filter_ar_invoice_number].present?
    accounts_receivable_invoices_scope = accounts_receivable_invoices_scope.where(["order_bookings.customer_id = ?", params[:filter_ar_invoice_customer_id]]) if params[:filter_ar_invoice_customer_id].present?
    accounts_receivable_invoices_scope = accounts_receivable_invoices_scope.where(["due_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_ar_invoice_due_date].present?
    accounts_receivable_invoices_scope = accounts_receivable_invoices_scope.where(remaining_debt_query) if params[:filter_ar_invoice_status].present?
    smart_listing_create(:accounts_receivable_invoices, accounts_receivable_invoices_scope, partial: 'accounts_receivable_invoices/listing', default_sort: {due_date: "asc"})
  end

  # GET /accounts_receivable_invoices/1
  # GET /accounts_receivable_invoices/1.json
  def show
    @company = Company.select(:id, :name, :address, :phone, :fax).first
    @accounts_receivable_invoice = AccountsReceivableInvoice.
      select(:id, :number, :created_at, :due_date, :shipment_id, :note, "customers.name AS customer_name", "customers.phone AS customer_phone", "customers.facsimile AS customer_facsimile", "shipments.delivery_order_number", "customers.is_taxable_entrepreneur AS customer_is_taxable_entrepreneur", "customers.value_added_tax AS customer_vat_type").
      joins(shipment: [order_booking: :customer]).
      includes(shipment_product_items: [:price_list, order_booking_product_item: [:color, :size, order_booking_product: [product: :brand]]]).
      find(params[:id])
  end

  # GET /accounts_receivable_invoices/new
  def new
    @accounts_receivable_invoice = AccountsReceivableInvoice.new
  end

  # GET /accounts_receivable_invoices/1/edit
  def edit
  end

  # POST /accounts_receivable_invoices
  # POST /accounts_receivable_invoices.json
  def create
    @accounts_receivable_invoice = AccountsReceivableInvoice.new(accounts_receivable_invoice_params)
    recreate = false
    recreate_counter = 1
    begin
      begin
        recreate = false
        unless @created = @accounts_receivable_invoice.save          
          if @accounts_receivable_invoice.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@accounts_receivable_invoice.errors[:base].join("<br/>")}\",size: 'small'});"
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

  # PATCH/PUT /accounts_receivable_invoices/1
  # PATCH/PUT /accounts_receivable_invoices/1.json
  def update
    respond_to do |format|
      if @accounts_receivable_invoice.update(accounts_receivable_invoice_params)
        format.html { redirect_to @accounts_receivable_invoice, notice: 'Accounts receivable invoice was successfully updated.' }
        format.json { render :show, status: :ok, location: @accounts_receivable_invoice }
      else
        format.html { render :edit }
        format.json { render json: @accounts_receivable_invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /accounts_receivable_invoices/1
  # DELETE /accounts_receivable_invoices/1.json
  def destroy
    @deleted = @accounts_receivable_invoice.destroy
  end
  
  def get_shipment_detail
    @shipment = Shipment.
      select(:id, :delivery_order_number, :quantity, "customers.is_taxable_entrepreneur AS customer_is_taxable_entrepreneur", "customers.value_added_tax AS customer_vat_type", "customers.code AS customer_code", "customers.name AS customer_name").
      joins(order_booking: :customer).
      where(invoiced: false).
      where("order_bookings.customer_id IS NOT NULL").
      find(params[:shipment_id])
    @gross_amt = 0
    @shipment.shipment_product_items.select(:quantity, "price_lists.price").joins(:price_list).each do |spi|
      @gross_amt += spi.quantity * spi.price
    end
    @vat = if @shipment.customer_is_taxable_entrepreneur
      if @shipment.customer_vat_type.eql?("include")
        (@gross_amt / 1.1 * 0.1).round(2)
      else
        @gross_amt * 0.1
      end
    else
      0
    end
    @net_amt = if @shipment.customer_is_taxable_entrepreneur
      if @shipment.customer_vat_type.eql?("include")
        @gross_amt
      else
        @gross_amt + @gross_amt * 0.1
      end
    else
      @gross_amt
    end
  end
  
  def print
    @company = Company.select(:id, :name, :address, :phone, :fax).first
    @accounts_receivable_invoice = AccountsReceivableInvoice.
      select(:id, :number, :created_at, :due_date, :shipment_id, :note, "customers.name AS customer_name", "customers.phone AS customer_phone", "customers.facsimile AS customer_facsimile", "shipments.delivery_order_number", "customers.is_taxable_entrepreneur AS customer_is_taxable_entrepreneur", "customers.value_added_tax AS customer_vat_type").
      joins(shipment: [order_booking: :customer]).
      includes(shipment_product_items: [:price_list, order_booking_product_item: [:color, :size, order_booking_product: [product: :brand]]]).
      find(params[:id])
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_accounts_receivable_invoice
    @accounts_receivable_invoice = AccountsReceivableInvoice.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def accounts_receivable_invoice_params
    params.require(:accounts_receivable_invoice).permit(:note, :shipment_id, :attr_customer_info, :attr_shipment_quantity, :attr_gross_amount, :attr_vat_value, :attr_net_amount)
  end
end
