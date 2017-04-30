include SmartListing::Helper::ControllerExtensions
class AccountPayablesController < ApplicationController
  before_action :set_account_payable, only: [:show, :edit, :update, :destroy]
  helper SmartListing::Helper

  # GET /account_payables
  # GET /account_payables.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_payment_date].present?
      splitted_date_range = params[:filter_payment_date].split("-")
      start_date = splitted_date_range[0].strip.to_date
      end_date = splitted_date_range[1].strip.to_date
    end
    account_payables_scope = AccountPayable.select("account_payables.id, number, vendors.name, payment_date").joins(:vendor)
    account_payables_scope = account_payables_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(account_payables_scope.where(["vendors.name #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    account_payables_scope = account_payables_scope.where(["DATE(payment_date) BETWEEN ? AND ?", start_date, end_date]) if params[:filter_payment_date].present?
    @account_payables = smart_listing_create(:account_payables, account_payables_scope, partial: 'account_payables/listing', default_sort: {number: "asc"})
  end

  # GET /account_payables/1
  # GET /account_payables/1.json
  def show
  end

  # GET /account_payables/new
  def new
    @account_payable = AccountPayable.new
    @purchase_orders = PurchaseOrder.select(:id, :number, :purchase_order_date, :receiving_value, :first_discount, :second_discount, :is_taxable_entrepreneur, :value_added_tax, :is_additional_disc_from_net, :net_amount, :payment_status).select("vendors.name AS vendor_name").joins(:received_purchase_orders, :vendor).where("(status = 'Finish' OR status = 'Closed') AND (payment_status = 'Paid' OR payment_status = '')").group("purchase_orders.id, received_purchase_orders.receiving_date, vendors.name").order("received_purchase_orders.receiving_date")
    @direct_purchases = DirectPurchase.select(:id, :delivery_order_number, :receiving_date, :first_discount, :second_discount, :is_taxable_entrepreneur, :vat_type, :is_additional_disc_from_net, :payment_status).select("vendors.name AS vendor_name").joins(:received_purchase_order, :vendor).order(:receiving_date)
  end

  # GET /account_payables/1/edit
  def edit
  end

  # POST /account_payables
  # POST /account_payables.json
  def create
    convert_amount_to_numeric
    @account_payable = AccountPayable.new(account_payable_params)
    is_exception_raised = false
    begin
      unless @account_payable.save
        previous_account_payables = []
        @account_payable.account_payable_purchases.map(&:purchase_id).each do |purchase_order_id|
          account_payables = AccountPayable.select(:id, :amount_paid, :amount_returned).
            joins(:account_payable_purchases).
            where("purchase_id = '#{purchase_order_id}' AND purchase_type = 'PurchaseOrder'")
          account_payables.each do |account_payable|        
            previous_account_payables << account_payable
          end
        end    
    
        # kalkulasi pembayaran pembayaran sebelumnya
        @previous_paid = 0
        previous_account_payables.uniq.each do |previous_account_payable|
          @previous_paid += previous_account_payable.amount_paid + previous_account_payable.amount_returned.to_f
        end
    
        if @account_payable.errors[:"account_payable_purchases.base"].present?
          render js: "bootbox.alert({message: \"#{@account_payable.errors[:"account_payable_purchases.base"].join("<br/>")}\",size: 'small'});"
        elsif @account_payable.errors[:base].present?
          render js: "bootbox.alert({message: \"#{@account_payable.errors[:base].join("<br/>")}\",size: 'small'});"
        elsif @account_payable.errors[:"allocated_return_items.base"].present?
          render js: "bootbox.alert({message: \"#{@account_payable.errors[:"allocated_return_items.base"].join("<br/>")}\",size: 'small'});"
        end
      else
        SendEmailJob.perform_later(@account_payable)
        @vendor_name = Vendor.select(:name).where(id: @account_payable.vendor_id).first.name
      end
      is_exception_raised = false
    rescue ActiveRecord::RecordNotUnique => e
      is_exception_raised = true
    end while is_exception_raised
  end
  
  def create_dp_payment
    convert_amount_to_numeric
    @account_payable = AccountPayable.new(account_payable_params)
    @account_payable.payment_for_dp = true
    is_exception_raised = false
    begin
      unless @account_payable.save
        @payment_for_dp = true
        previous_account_payables = []
        @account_payable.account_payable_purchases.map(&:purchase_id).each do |direct_purchase_id|
          account_payables = AccountPayable.select(:id, :amount_paid, :amount_returned).
            joins(:account_payable_purchases).
            where("purchase_id = '#{direct_purchase_id}' AND purchase_type = 'DirectPurchase'")
          account_payables.each do |account_payable|        
            previous_account_payables << account_payable
          end
        end    
    
        # kalkulasi pembayaran pembayaran sebelumnya
        @previous_paid = 0
        previous_account_payables.uniq.each do |previous_account_payable|
          @previous_paid += previous_account_payable.amount_paid + previous_account_payable.amount_returned.to_f
        end
    
        if @account_payable.errors[:"account_payable_purchases.base"].present?
          render js: "bootbox.alert({message: \"#{@account_payable.errors[:"account_payable_purchases.base"].join("<br/>")}\",size: 'small'});"
        elsif @account_payable.errors[:base].present?
          render js: "bootbox.alert({message: \"#{@account_payable.errors[:base].join("<br/>")}\",size: 'small'});"
        elsif @account_payable.errors[:"allocated_return_items.base"].present?
          render js: "bootbox.alert({message: \"#{@account_payable.errors[:"allocated_return_items.base"].join("<br/>")}\",size: 'small'});"
        end
      else
        SendEmailJob.perform_later(@account_payable)
        @vendor_name = Vendor.select(:name).where(id: @account_payable.vendor_id).first.name
      end
      is_exception_raised = false
    rescue ActiveRecord::RecordNotUnique => e
      is_exception_raised = true
    end while is_exception_raised
  end

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
    # ambil seluruh purchase order dari payment sebelumnya
    purchase_order_ids = []
    params[:purchase_order_ids].split(",").each do |purchase_order_id|
      account_payables = AccountPayable.select(:id, :amount_paid).
        joins(:account_payable_purchases).
        where("purchase_id = '#{purchase_order_id}' AND purchase_type = 'PurchaseOrder'")
      if account_payables.present?
        account_payables.each do |account_payable|        
          account_payable.account_payable_purchases.pluck(:purchase_id).each do |purchase_id|
            purchase_order_ids << purchase_id if PurchaseOrder.select("1 AS one").where(["id = ? AND payment_status <> 'Paid'", purchase_id]).present?
          end
        end
      else
        purchase_order_ids << purchase_order_id
      end
    end    
    purchase_order_ids.uniq!
    
    # kalkulasi pembayaran pembayaran sebelumnya
    previous_account_payables = []
    purchase_order_ids.each do |purchase_order_id|
      account_payables = AccountPayable.select(:id, :amount_paid, :amount_returned).
        joins(:account_payable_purchases).
        where("purchase_id = '#{purchase_order_id}' AND purchase_type = 'PurchaseOrder'")
      account_payables.each do |account_payable|        
        previous_account_payables << account_payable
      end
    end    
    @previous_paid = 0
    previous_account_payables.uniq.each do |previous_account_payable|
      @previous_paid += previous_account_payable.amount_paid + previous_account_payable.amount_returned.to_f
    end
    
    selected_purchase_orders = PurchaseOrder.where(id: purchase_order_ids).select(:id, :number, :receiving_value, :first_discount, :second_discount, :is_taxable_entrepreneur, :value_added_tax, :is_additional_disc_from_net, :vendor_id, :name).select("vendors.id AS vendor_id").joins(:vendor).where("status = 'Finish' OR status = 'Closed'").where(payment_status: "")
    selected_purchase_orders.each_with_index do |selected_purchase_order, index|
      @account_payable = AccountPayable.new vendor_id: selected_purchase_order.vendor_id if index == 0
      @account_payable.account_payable_purchases.build purchase_id: selected_purchase_order.id, purchase_type: selected_purchase_order.class.name
    end
    render js: "bootbox.alert({message: \"Please choose one vendor to make a payment\",size: 'small'});" if selected_purchase_orders.pluck(:vendor_id).uniq.length > 1
    render js: "bootbox.alert({message: \"Please select another purchase order\",size: 'small'});" if selected_purchase_orders.length == 0
  end
  
  def generate_dp_payment_form
    # ambil seluruh direct purchase dari payment sebelumnya
    direct_purchase_ids = []
    params[:direct_purchase_ids].split(",").each do |direct_purchase_id|
      account_payables = AccountPayable.select(:id, :amount_paid).
        joins(:account_payable_purchases).
        where("purchase_id = '#{direct_purchase_id}' AND purchase_type = 'DirectPurchase'")
      if account_payables.present?
        account_payables.each do |account_payable|        
          account_payable.account_payable_purchases.pluck(:purchase_id).each do |purchase_id|
            direct_purchase_ids << purchase_id if DirectPurchase.select("1 AS one").where(["id = ? AND payment_status <> 'Paid'", purchase_id]).present?
          end
        end
      else
        direct_purchase_ids << direct_purchase_id
      end
    end    
    direct_purchase_ids.uniq!
    
    # kalkulasi pembayaran pembayaran sebelumnya
    previous_account_payables = []
    direct_purchase_ids.each do |direct_purchase_id|
      account_payables = AccountPayable.select(:id, :amount_paid, :amount_returned).
        joins(:account_payable_purchases).
        where("purchase_id = '#{direct_purchase_id}' AND purchase_type = 'DirectPurchase'")
      account_payables.each do |account_payable|        
        previous_account_payables << account_payable
      end
    end    
    @previous_paid = 0
    previous_account_payables.uniq.each do |previous_account_payable|
      @previous_paid += previous_account_payable.amount_paid + previous_account_payable.amount_returned.to_f
    end
    
    selected_direct_purchases = DirectPurchase.where(id: direct_purchase_ids).select(:id, :vendor_id).where(payment_status: "")
    selected_direct_purchases.each_with_index do |selected_direct_purchase, index|
      @account_payable = AccountPayable.new vendor_id: selected_direct_purchase.vendor_id if index == 0
      @account_payable.account_payable_purchases.build purchase_id: selected_direct_purchase.id, purchase_type: selected_direct_purchase.class.name
    end
    render js: "bootbox.alert({message: \"Please choose one vendor to make a payment\",size: 'small'});" if selected_direct_purchases.pluck(:vendor_id).uniq.length > 1
    render js: "bootbox.alert({message: \"Please select another purchase record\",size: 'small'});" if selected_direct_purchases.length == 0
  end
  
  def get_purchase_returns
    @purchase_returns = Vendor.where(["id = ?", params[:vendor_id]]).select(:id).first.po_returns
    render partial: 'show_return_items'
  end

  def get_purchase_returns_for_dp
    @purchase_returns = Vendor.where(["id = ?", params[:vendor_id]]).select(:id).first.dp_returns
    render partial: 'show_return_items'
  end
  
  def select_purchase_return
    @account_payable = AccountPayable.new
    params[:purchase_return_ids].split(",").each do |purchase_return_id|
      purchase_return = PurchaseReturn.where(["vendor_id = ? AND purchase_returns.id = ? AND is_allocated = ? AND purchase_order_id IS NOT NULL", params[:vendor_id], purchase_return_id, false]).joins(purchase_order: :vendor).select("purchase_returns.id").first
      @account_payable.allocated_return_items.build purchase_return_id: purchase_return.id, payment_for_dp: false if purchase_return
    end
  end
  
  def select_purchase_return_for_dp
    @payment_for_dp = true
    @account_payable = AccountPayable.new
    params[:purchase_return_ids].split(",").each do |purchase_return_id|
      purchase_return = PurchaseReturn.where(["vendor_id = ? AND purchase_returns.id = ? AND is_allocated = ? AND direct_purchase_id IS NOT NULL", params[:vendor_id], purchase_return_id, false]).joins(direct_purchase: :vendor).select("purchase_returns.id").first
      @account_payable.allocated_return_items.build purchase_return_id: purchase_return.id, payment_for_dp: true if purchase_return
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_payable
    @account_payable = AccountPayable.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_payable_params
    params.require(:account_payable).permit(:payment_date, :payment_method, :vendor_id, :giro_number, :giro_date, :amount_paid, :debt, account_payable_purchases_attributes: [:purchase_id, :purchase_type], allocated_return_items_attributes: [:purchase_return_id, :vendor_id, :payment_for_dp]).merge(created_by: current_user.id)
  end
  
  def convert_amount_to_numeric
    params[:account_payable][:amount_paid] = params[:account_payable][:amount_paid].gsub("Rp","").gsub(".","").gsub(",",".") if params[:account_payable][:amount_paid].present?
    params[:account_payable][:debt] = params[:account_payable][:debt].gsub("Rp","").gsub(".","").gsub(",",".") if params[:account_payable][:debt].present?
  end
end
