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
    account_payables_scope = AccountPayable.select("account_payables.id, number, amount_paid, vendors.name, payment_date").joins(:vendor)
    account_payables_scope = account_payables_scope.where(["number #{like_command} ?", "%"+params[:filter]+"%"]).
      or(account_payables_scope.where(["amount_paid #{like_command} ?", "%"+params[:filter]+"%"])).
      or(account_payables_scope.where(["vendors.name #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @account_payables = smart_listing_create(:account_payables, account_payables_scope, partial: 'account_payables/listing', default_sort: {number: "asc"})
  end

  # GET /account_payables/1
  # GET /account_payables/1.json
  def show
  end

  # GET /account_payables/new
  def new
    @account_payable = AccountPayable.new
    @purchase_orders = PurchaseOrder.select(:id, :number, :purchase_order_date, :receiving_value, :first_discount, :second_discount, :price_discount, :is_taxable_entrepreneur, :value_added_tax, :is_additional_disc_from_net, :net_amount, :payment_status).select("vendors.name AS vendor_name").joins(:received_purchase_orders, :vendor).where("(status = 'Finish' OR status = 'Closed') AND (payment_status = 'Paid' OR payment_status = '')").group("purchase_orders.id, vendors.name").order("received_purchase_orders.receiving_date")
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
        @purchase_orders = PurchaseOrder.select(:id, :number, :purchase_order_date, :receiving_value, :first_discount, :second_discount, :price_discount, :is_taxable_entrepreneur, :value_added_tax, :is_additional_disc_from_net, :net_amount, :payment_status).select("vendors.name AS vendor_name").joins(:received_purchase_orders, :vendor).where("status = 'Finish' OR status = 'Closed'").group("purchase_orders.id, vendors.name").order("received_purchase_orders.receiving_date")
        
        previous_account_payables = []
        @account_payable.account_payable_purchases.map(&:purchase_id).each do |purchase_order_id|
          account_payables = AccountPayable.select(:id, :amount_paid).joins(:account_payable_purchases).where("purchase_id = '#{purchase_order_id}' AND purchase_type = 'PurchaseOrder'")
          account_payables.each do |account_payable|        
            previous_account_payables << account_payable
          end
        end    
    
        # kalkulasi pembayaran pembayaran sebelumnya
        @previous_paid = 0
        previous_account_payables.uniq.each do |previous_account_payable|
          @previous_paid += previous_account_payable.amount_paid      
        end
    
        render js: "bootbox.alert({message: \"#{@account_payable.errors[:"account_payable_purchases.base"].join("<br/>")}\",size: 'small'});" if @account_payable.errors[:"account_payable_purchases.base"].present?
      else
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
      account_payables = AccountPayable.select(:id, :amount_paid).joins(:account_payable_purchases).where("purchase_id = '#{purchase_order_id}' AND purchase_type = 'PurchaseOrder'")
      if account_payables.present?
        account_payables.each do |account_payable|        
          account_payable.account_payable_purchases.pluck(:purchase_id).each do |purchase_id|
            purchase_order_ids << purchase_id
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
      account_payables = AccountPayable.select(:id, :amount_paid).joins(:account_payable_purchases).where("purchase_id = '#{purchase_order_id}' AND purchase_type = 'PurchaseOrder'")
      account_payables.each do |account_payable|        
        previous_account_payables << account_payable
      end
    end    
    @previous_paid = 0
    previous_account_payables.uniq.each do |previous_account_payable|
      @previous_paid += previous_account_payable.amount_paid      
    end
    
    selected_purchase_orders = PurchaseOrder.where(id: purchase_order_ids).select(:id, :number, :receiving_value, :first_discount, :second_discount, :price_discount, :is_taxable_entrepreneur, :value_added_tax, :is_additional_disc_from_net, :vendor_id, :name).select("vendors.id AS vendor_id").joins(:vendor).where("status = 'Finish' OR status = 'Closed'").where(payment_status: "")
    selected_purchase_orders.each_with_index do |selected_purchase_order, index|
      @account_payable = AccountPayable.new vendor_id: selected_purchase_order.vendor_id if index == 0
      @account_payable.account_payable_purchases.build purchase_id: selected_purchase_order.id, purchase_type: selected_purchase_order.class.name
    end
    render js: "bootbox.alert({message: \"Please choose one vendor to make a payment\",size: 'small'});" if selected_purchase_orders.pluck(:vendor_id).uniq.length > 1
    render js: "bootbox.alert({message: \"Please select another purchase order\",size: 'small'});" if selected_purchase_orders.length == 0
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_account_payable
    @account_payable = AccountPayable.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def account_payable_params
    params.require(:account_payable).permit(:payment_date, :payment_method, :vendor_id, :giro_number, :giro_date, :amount_paid, :debt, account_payable_purchases_attributes: [:purchase_id, :purchase_type])
  end
  
  def convert_amount_to_numeric
    params[:account_payable][:amount_paid] = params[:account_payable][:amount_paid].gsub("Rp","").gsub(".","").gsub(",",".") if params[:account_payable][:amount_paid].present?
    params[:account_payable][:debt] = params[:account_payable][:debt].gsub("Rp","").gsub(".","").gsub(",",".") if params[:account_payable][:debt].present?
  end
end
