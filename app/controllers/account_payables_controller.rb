include SmartListing::Helper::ControllerExtensions
class AccountPayablesController < ApplicationController
  authorize_resource
  before_action :set_account_payable, only: [:show, :edit, :update, :destroy, :print]
  helper SmartListing::Helper

  # GET /account_payables
  # GET /account_payables.json
  def index
    like_command = "ILIKE"
    account_payables_scope = AccountPayable.select("account_payables.id, number, vendors.name, total, remaining_debt").joins(:vendor)
    account_payables_scope = account_payables_scope.where(["number #{like_command} ?", "%"+params[:filter]+"%"]).
      or(account_payables_scope.where(["vendors.name #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter].present?
    @account_payables = smart_listing_create(:account_payables, account_payables_scope, partial: 'account_payables/listing', default_sort: {number: "asc"})
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
    @account_payable = AccountPayable.new
    @purchase_orders = PurchaseOrder.select(:id, :number, :purchase_order_date,
      :receiving_value, :first_discount, :second_discount, :is_taxable_entrepreneur,
      :value_added_tax,:is_additional_disc_from_net, :net_amount, :invoice_status).
      select("vendors.name AS vendor_name").joins(:received_purchase_orders, :vendor).
      where("(status = 'Finish' OR status = 'Closed') AND invoice_status = ''").
      order("received_purchase_orders.receiving_date")
    @direct_purchases = DirectPurchase.
      select(:id, :delivery_order_number, :receiving_date, :first_discount, :second_discount, :is_taxable_entrepreneur, :vat_type, :is_additional_disc_from_net, :invoice_status).
      select("vendors.name AS vendor_name").
      joins(:received_purchase_order, :vendor).
      where(invoice_status: "").
      order(:receiving_date)
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
      @account_payable = AccountPayable.new vendor_id: selected_purchase.vendor_id if index == 0
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

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_payable
    @account_payable = AccountPayable.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_payable_params
    params.require(:account_payable).permit(:vendor_id,
      :note, :vendor_invoice_number, :vendor_invoice_date,
      account_payable_purchases_attributes: [:purchase_id, :purchase_type, :vendor_id])
  end
  
  def add_additional_params_to_child
    params[:account_payable][:account_payable_purchases_attributes].each do |key, value|
      params[:account_payable][:account_payable_purchases_attributes][key].merge! vendor_id: params[:account_payable][:vendor_id]
    end if params[:account_payable][:account_payable_purchases_attributes].present?
  end

end
