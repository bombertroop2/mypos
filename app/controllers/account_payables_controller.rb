include SmartListing::Helper::ControllerExtensions
class AccountPayablesController < ApplicationController
  include AccountPayablesHelper
  authorize_resource
  before_action :set_account_payable, only: [:show, :edit, :update, :destroy, :print]
  helper SmartListing::Helper

  # GET /account_payables
  # GET /account_payables.json
  def index
    if params[:filter_ap_invoice_vendor_invoice_date].present?
      splitted_date_range = params[:filter_ap_invoice_vendor_invoice_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end
    
    if params[:filter_ap_invoice_status].present?
      remaining_debt_query = if params[:filter_ap_invoice_status].eql?("All")
        "remaining_debt >= 0"
      elsif params[:filter_ap_invoice_status].eql?("Paid off")
        "remaining_debt = 0"
      else
        "remaining_debt > 0"
      end
    end

    account_payables_scope = AccountPayable.select("account_payables.id, number, vendors.name, total, remaining_debt", :vendor_invoice_number, :vendor_invoice_date).joins(:vendor)
    account_payables_scope = account_payables_scope.where(["number ILIKE ? OR vendor_invoice_number ILIKE ?", "%"+params[:filter_ap_invoice_invoice_number]+"%", "%"+params[:filter_ap_invoice_invoice_number]+"%"]) if params[:filter_ap_invoice_invoice_number].present?
    account_payables_scope = account_payables_scope.where(["vendor_id = ?", params[:filter_ap_invoice_vendor_id]]) if params[:filter_ap_invoice_vendor_id].present?
    account_payables_scope = account_payables_scope.where(["vendor_invoice_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_ap_invoice_vendor_invoice_date].present?
    account_payables_scope = account_payables_scope.where(remaining_debt_query) if params[:filter_ap_invoice_status].present?
    smart_listing_create(:account_payables, account_payables_scope, partial: 'account_payables/listing', default_sort: {number: "asc"})
  end

  # GET /account_payables/1
  # GET /account_payables/1.json
  def show
  end
  
  def print
    @vendor_name = Vendor.select(:name).where(id: @account_payable.vendor_id).first.name
  end

  # GET /account_payables/new
  def new
    gv = GeneralVariable.select(:beginning_of_account_payable_creating).first
    @account_payable = AccountPayable.new beginning_of_account_payable_creating: gv.beginning_of_account_payable_creating
    if gv.beginning_of_account_payable_creating.eql?("Closed/Finish")
      @purchase_orders = PurchaseOrder.select(:id, :number, :purchase_order_date,
        :receiving_value, :first_discount, :second_discount, :is_taxable_entrepreneur,
        :value_added_tax,:is_additional_disc_from_net, :net_amount, :invoice_status).
        select("vendors.name AS vendor_name").joins(:received_purchase_orders, :vendor).
        where("(status = 'Finish' OR status = 'Closed') AND purchase_orders.invoice_status = ''").
        order("received_purchase_orders.receiving_date")
      @direct_purchases = DirectPurchase.
        select(:id, :delivery_order_number, :receiving_date, :first_discount, :second_discount, :is_taxable_entrepreneur, :vat_type, :is_additional_disc_from_net, :invoice_status).
        select("vendors.name AS vendor_name").
        joins(:received_purchase_order, :vendor).
        where(invoice_status: "").
        order(:receiving_date)
    end
  end

  # GET /account_payables/1/edit
  def edit
  end

  # POST /account_payables
  # POST /account_payables.json
  def create
    add_additional_params_to_child
    @account_payable = AccountPayable.new(account_payable_params)
    unless @account_payable.save
      if @account_payable.errors[:"account_payable_purchases.base"].present?
        render js: "bootbox.alert({message: \"#{@account_payable.errors[:"account_payable_purchases.base"].join("<br/>")}\",size: 'small'});"
      elsif @account_payable.errors[:base].present?
        render js: "bootbox.alert({message: \"#{@account_payable.errors[:base].join("<br/>")}\",size: 'small'});"
      end
    else
      #      SendEmailJob.perform_later(@account_payable)
      @vendor_name = Vendor.select(:name).where(id: @account_payable.vendor_id).first.name
    end
  rescue ActiveRecord::RecordNotUnique => e
    render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
  end
  
  #  def create_dp_payment
  #    add_additional_params_to_child
  #    @account_payable = AccountPayable.new(account_payable_params)
  #    @account_payable.payment_for_dp = true
  #    unless @account_payable.save
  #      @payment_for_dp = true    
  #      if @account_payable.errors[:"account_payable_purchases.base"].present?
  #        render js: "bootbox.alert({message: \"#{@account_payable.errors[:"account_payable_purchases.base"].join("<br/>")}\",size: 'small'});"
  #      elsif @account_payable.errors[:base].present?
  #        render js: "bootbox.alert({message: \"#{@account_payable.errors[:base].join("<br/>")}\",size: 'small'});"
  #      end
  #    else
  #      #      SendEmailJob.perform_later(@account_payable)
  #      @vendor_name = Vendor.select(:name).where(id: @account_payable.vendor_id).first.name
  #    end
  #  rescue ActiveRecord::RecordNotUnique => e
  #    render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
  #  end

  # PATCH/PUT /account_payables/1
  # PATCH/PUT /account_payables/1.json
  def update
    respond_to do |format|
      if @account_payable.update(account_payable_params)
        format.html { redirect_to @account_payable, notice: 'Account payable was successfully updated.' }
        format.json { render :show, status: :ok, location: @account_payable }
      else
        format.html { render :edit }
        format.json { render json: @account_payable.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account_payables/1
  # DELETE /account_payables/1.json
  def destroy
    @account_payable.destroy
    if @account_payable.errors.present? and @account_payable.errors.messages[:base].present?
      flash[:alert] = @account_payable.errors.messages[:base].to_sentence
      render js: "window.location = '#{account_payables_url}'"
    end
  end
  
  def generate_form
    selected_purchases = []
    params[:purchase_types].each_with_index do |pt, index|
      if pt.eql?("purchase_order")
        selected_purchases << PurchaseOrder.select(:id, :number, :receiving_value, :first_discount, :second_discount, :is_taxable_entrepreneur, :value_added_tax, :is_additional_disc_from_net, :vendor_id, :name).select("vendors.id AS vendor_id").joins(:vendor).where("status = 'Finish' OR status = 'Closed'").where(invoice_status: "").where(["vendors.is_active = ?", true]).find(params[:purchase_ids][index])
      else
        selected_purchases << DirectPurchase.select(:id, :vendor_id).joins(:vendor).where(invoice_status: "").where(["vendors.is_active = ?", true]).find(params[:purchase_ids][index])
      end
    end
    selected_purchases.each_with_index do |selected_purchase, index|
      @account_payable = AccountPayable.new vendor_id: selected_purchase.vendor_id, beginning_of_account_payable_creating: "Closed/Finish" if index == 0
      @account_payable.account_payable_purchases.build purchase_id: selected_purchase.id, purchase_type: selected_purchase.class.name
    end
    render js: "bootbox.alert({message: \"Please choose one vendor to make a payment\",size: 'small'});" if selected_purchases.pluck(:vendor_id).uniq.length > 1
    render js: "bootbox.alert({message: \"Please select another purchase order\",size: 'small'});" if selected_purchases.length == 0
  end
  
  #  def generate_dp_payment_form
  #    selected_direct_purchases = DirectPurchase.where(id: params[:direct_purchase_ids].split(",").uniq).select(:id, :vendor_id).where(invoice_status: "")
  #    selected_direct_purchases.each_with_index do |selected_direct_purchase, index|
  #      @account_payable = AccountPayable.new vendor_id: selected_direct_purchase.vendor_id if index == 0
  #      @account_payable.account_payable_purchases.build purchase_id: selected_direct_purchase.id, purchase_type: selected_direct_purchase.class.name
  #    end
  #    render js: "bootbox.alert({message: \"Please choose one vendor to make a payment\",size: 'small'});" if selected_direct_purchases.pluck(:vendor_id).uniq.length > 1
  #    render js: "bootbox.alert({message: \"Please select another purchase record\",size: 'small'});" if selected_direct_purchases.length == 0
  #  end
  
  #  def get_purchase_returns
  #    @purchase_returns = Vendor.where(["id = ?", params[:vendor_id]]).select(:id).first.po_returns
  #    render partial: 'show_return_items'
  #  end

  #  def get_purchase_returns_for_dp
  #    @purchase_returns = Vendor.where(["id = ?", params[:vendor_id]]).select(:id).first.dp_returns
  #    render partial: 'show_return_items'
  #  end
  # SUDAH TIDAK DIPAKAI
  #  def select_purchase_return
  #    @account_payable = AccountPayable.new
  #    params[:purchase_return_ids].split(",").each do |purchase_return_id|
  #      purchase_return = PurchaseReturn.where(["vendor_id = ? AND purchase_returns.id = ? AND is_allocated = ? AND purchase_order_id IS NOT NULL", params[:vendor_id], purchase_return_id, false]).joins(purchase_order: :vendor).select("purchase_returns.id").first
  #      @account_payable.allocated_return_items.build purchase_return_id: purchase_return.id, payment_for_dp: false if purchase_return
  #    end
  #  end

  # SUDAH TIDAK DIPAKAI
  #  def select_purchase_return_for_dp
  #    @payment_for_dp = true
  #    @account_payable = AccountPayable.new
  #    params[:purchase_return_ids].split(",").each do |purchase_return_id|
  #      purchase_return = PurchaseReturn.where(["vendor_id = ? AND purchase_returns.id = ? AND is_allocated = ? AND direct_purchase_id IS NOT NULL", params[:vendor_id], purchase_return_id, false]).joins(direct_purchase: :vendor).select("purchase_returns.id").first
  #      @account_payable.allocated_return_items.build purchase_return_id: purchase_return.id, payment_for_dp: true if purchase_return
  #    end
  #  end
  
  def get_received_purchases
    account_payable = AccountPayable.new
    received_purchase_orders = ReceivedPurchaseOrder.
      select(:id, :delivery_order_number, :receiving_date, :quantity, :purchase_order_id, :direct_purchase_id, "purchase_orders.number AS po_number", "purchase_orders.first_discount AS po_first_discount", "direct_purchases.first_discount AS dp_first_discount", "purchase_orders.second_discount AS po_second_discount", "direct_purchases.second_discount AS dp_second_discount", "purchase_orders.is_additional_disc_from_net AS po_is_additional_disc_from_net", "direct_purchases.is_additional_disc_from_net AS dp_is_additional_disc_from_net", "purchase_orders.is_taxable_entrepreneur AS po_is_taxable_entrepreneur", "direct_purchases.is_taxable_entrepreneur AS dp_is_taxable_entrepreneur", "purchase_orders.value_added_tax AS po_vat_type", "direct_purchases.vat_type AS dp_vat_type").
      joins(:vendor).
      joins("LEFT JOIN purchase_orders ON received_purchase_orders.purchase_order_id = purchase_orders.id").
      joins("LEFT JOIN direct_purchases ON received_purchase_orders.direct_purchase_id = direct_purchases.id").
      includes(received_purchase_order_products: [:received_purchase_order_items, purchase_order_product: :cost_list, direct_purchase_product: :cost_list]).
      where(vendor_id: params[:vendor_id], invoice_status: "").
      where(["vendors.is_active = ? AND (purchase_orders.invoice_status <> 'Invoiced' OR direct_purchases.invoice_status <> 'Invoiced') AND received_purchase_orders.receiving_date <= ?", true, params[:vendor_invoice_date].to_date])
    @account_payable_purchase_partials = []
    received_purchase_orders.each do |rpo|
      gross_amount = 0
      rpo.received_purchase_order_products.each do |rpop|
        rpop.received_purchase_order_items.each do |rpoi|
          if rpop.purchase_order_product_id.present?
            gross_amount += rpoi.quantity * rpop.purchase_order_product.cost_list.cost
          else
            gross_amount += rpoi.quantity * rpop.direct_purchase_product.cost_list.cost
          end
        end
      end
      first_discount = if rpo.purchase_order_id.present? && rpo.po_first_discount.present?
        rpo.po_first_discount
      elsif rpo.direct_purchase_id.present? && rpo.dp_first_discount.present?
        rpo.dp_first_discount
      end
      first_discount_money = if rpo.purchase_order_id.present? && rpo.po_first_discount.present?
        (rpo.po_first_discount.to_f / 100) * gross_amount
      elsif rpo.direct_purchase_id.present? && rpo.dp_first_discount.present?
        (rpo.dp_first_discount.to_f / 100) * gross_amount
      end
      second_discount = if rpo.purchase_order_id.present? && rpo.po_second_discount.present?
        rpo.po_second_discount
      elsif rpo.direct_purchase_id.present? && rpo.dp_second_discount.present?
        rpo.dp_second_discount
      end
      second_discount_money = if rpo.purchase_order_id.present? && rpo.po_second_discount.present?
        get_second_discount_in_money_for_ap_partial rpo, "order", gross_amount
      elsif rpo.direct_purchase_id.present? && rpo.dp_second_discount.present?
        get_second_discount_in_money_for_ap_partial rpo, "direct", gross_amount        
      end
      is_additional_disc_from_net = if rpo.purchase_order_id.present? && rpo.po_second_discount.present?
        rpo.po_is_additional_disc_from_net
      elsif rpo.direct_purchase_id.present? && rpo.dp_second_discount.present?
        rpo.dp_is_additional_disc_from_net
      end
      is_taxable_entrepreneur = if rpo.purchase_order_id.present?
        rpo.po_is_taxable_entrepreneur
      else
        rpo.dp_is_taxable_entrepreneur
      end
      vat_in_money = if is_taxable_entrepreneur && rpo.purchase_order_id.present?
        if rpo.po_vat_type.eql?("include")
          get_include_vat_in_money_for_ap_partial rpo, "order", gross_amount
        else
          get_vat_in_money_for_ap_partial rpo, "order", gross_amount
        end
      elsif is_taxable_entrepreneur
        if rpo.dp_vat_type.eql?("include")
          get_include_vat_in_money_for_ap_partial rpo, "direct", gross_amount
        else
          get_vat_in_money_for_ap_partial rpo, "direct", gross_amount
        end
      end
      vat_type = if is_taxable_entrepreneur && rpo.purchase_order_id.present?
        rpo.po_vat_type
      elsif is_taxable_entrepreneur
        rpo.dp_vat_type
      end
      net_amount = if rpo.purchase_order_id.present?
        value_after_ppn_for_ap_partial rpo, "order", gross_amount
      else
        value_after_ppn_for_ap_partial rpo, "direct", gross_amount
      end
      @account_payable_purchase_partials << account_payable.account_payable_purchase_partials.build(received_purchase_order_id: rpo.id, attr_delivery_order_number: rpo.delivery_order_number, attr_purchase_order_number: rpo.po_number, attr_received_quantity: rpo.quantity, attr_gross_amount: gross_amount, attr_first_discount_money: first_discount_money, attr_second_discount_money: second_discount_money, attr_is_additional_disc_from_net: is_additional_disc_from_net, attr_vat_in_money: vat_in_money, attr_net_amount: net_amount, attr_receiving_date: rpo.receiving_date)
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_payable
    @account_payable = AccountPayable.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_payable_params
    if params[:account_payable][:beginning_of_account_payable_creating].eql?("Partial")
      params.require(:account_payable).permit(:vendor_id, :beginning_of_account_payable_creating,
        :note, :vendor_invoice_number, :vendor_invoice_date,
        account_payable_purchase_partials_attributes: [:received_purchase_order_id, :attr_delivery_order_number, :attr_purchase_order_number, :attr_received_quantity, :attr_gross_amount, :attr_first_discount_money, :attr_second_discount_money, :attr_vat_in_money, :attr_net_amount, :attr_receiving_date])
    else
      params.require(:account_payable).permit(:vendor_id, :beginning_of_account_payable_creating,
        :note, :vendor_invoice_number, :vendor_invoice_date,
        account_payable_purchases_attributes: [:purchase_id, :purchase_type, :vendor_id, :attr_vendor_invoice_date])
    end
  end
  
  def add_additional_params_to_child
    params[:account_payable][:account_payable_purchases_attributes].each do |key, value|
      params[:account_payable][:account_payable_purchases_attributes][key].merge! vendor_id: params[:account_payable][:vendor_id]
      params[:account_payable][:account_payable_purchases_attributes][key][:attr_vendor_invoice_date] = params[:account_payable][:vendor_invoice_date]
    end if params[:account_payable][:account_payable_purchases_attributes].present?
  end

end
