include SmartListing::Helper::ControllerExtensions
class PurchaseReturnsController < ApplicationController
  helper SmartListing::Helper
  before_action :set_purchase_return, only: [:show, :edit, :update, :destroy]

  # GET /purchase_returns
  # GET /purchase_returns.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    purchase_returns_scope = PurchaseReturn.joins("LEFT JOIN purchase_orders on purchase_returns.purchase_order_id = purchase_orders.id").joins("LEFT JOIN direct_purchases on purchase_returns.direct_purchase_id = direct_purchases.id").joins("INNER JOIN vendors ON vendors.id = purchase_orders.vendor_id OR vendors.id = direct_purchases.vendor_id").select("purchase_returns.id, purchase_returns.number, name")
    purchase_returns_scope = purchase_returns_scope.where(["purchase_returns.number #{like_command} ?", "%"+params[:filter]+"%"]).
      or(purchase_returns_scope.where(["name #{like_command} ?", "%"+params[:filter]+"%"])) if params[:filter]
    @purchase_returns = smart_listing_create(:purchase_returns, purchase_returns_scope, partial: 'purchase_returns/listing', default_sort: {:"purchase_returns.number" => "asc"})
  end

  # GET /purchase_returns/1
  # GET /purchase_returns/1.json
  def show
  end

  # GET /purchase_returns/new
  def new
    @purchase_return = PurchaseReturn.new direct_purchase_return: true
    @purchase_orders = PurchaseOrder.where("status != 'Open' AND status != 'Deleted'").select :id, :number
    @do_numbers = ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").order(:delivery_order_number)
  end

  # GET /purchase_returns/1/edit
  def edit
  end
  
  def create_direct_purchase_return
    merge_new_param_to_item_attributes
    @purchase_return = PurchaseReturn.new(purchase_return_params)
    is_exception_raised = false
    begin
      unless @purchase_return.save
        @purchase_return.purchase_return_products.each do |prp|
          direct_purchase_product = DirectPurchaseProduct.select(:id).where(id: prp.direct_purchase_product_id).first
          direct_purchase_product.direct_purchase_details.select(:id).each do |dpd|
            prp.purchase_return_items.build direct_purchase_detail_id: dpd.id if prp.purchase_return_items.select{|pri| pri.direct_purchase_detail_id.eql?(dpd.id)}.blank?
          end
        end
        @purchase_orders = PurchaseOrder.where("status != 'Open' AND status != 'Deleted'").select :id, :number
        @do_numbers = ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").order(:delivery_order_number)
        render js: "bootbox.alert({message: \"#{@purchase_return.errors[:base].join("\\n")}\",size: 'small'});" if @purchase_return.errors[:base].present?
      else
        @pr_number = @purchase_return.number
        @vendor_name = DirectPurchase.joins(:vendor).where(["direct_purchases.id = ?",@purchase_return.direct_purchase_id]).select("vendors.name").first.name
      end
      is_exception_raised = false
    rescue ActiveRecord::RecordNotUnique => e
      is_exception_raised = true
    end while is_exception_raised
  end

  # POST /purchase_returns
  # POST /purchase_returns.json
  def create
    @purchase_return = PurchaseReturn.new(purchase_return_params)
    is_exception_raised = false
    begin
      unless @purchase_return.save
        @purchase_return.purchase_return_products.each do |prp|
          prp.purchase_order_product.purchase_order_details.select(:id).each do |pod|
            prp.purchase_return_items.build purchase_order_detail_id: pod.id if prp.purchase_return_items.select{|pri| pri.purchase_order_detail_id.eql?(pod.id)}.blank?
          end
        end
        @purchase_orders = PurchaseOrder.where("status != 'Open' AND status != 'Deleted'").select :id, :number
        @do_numbers = ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").order(:delivery_order_number)
        render js: "bootbox.alert({message: \"#{@purchase_return.errors[:base].join("\\n")}\",size: 'small'});" if @purchase_return.errors[:base].present?
      else
        @pr_number = @purchase_return.number
        @vendor_name = PurchaseOrder.joins(:vendor).where(["purchase_orders.id = ?",@purchase_return.purchase_order_id]).select("vendors.name").first.name
      end
      is_exception_raised = false
    rescue ActiveRecord::RecordNotUnique => e
      is_exception_raised = true
    end while is_exception_raised
  end

  # PATCH/PUT /purchase_returns/1
  # PATCH/PUT /purchase_returns/1.json
  def update
    respond_to do |format|
      if @purchase_return.update(purchase_return_params)
        format.html { redirect_to @purchase_return, notice: 'Purchase return was successfully updated.' }
        format.json { render :show, status: :ok, location: @purchase_return }
      else
        format.html { render :edit }
        format.json { render json: @purchase_return.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /purchase_returns/1
  # DELETE /purchase_returns/1.json
  def destroy
    @purchase_return.destroy
    respond_to do |format|
      format.html { redirect_to purchase_returns_url, notice: 'Purchase return was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def get_purchase_order_details
    @purchase_return = PurchaseReturn.new
    purchase_order = PurchaseOrder.where(id: params[:purchase_order_id]).select(:id).first
    purchase_order.purchase_order_products.joins({product: :brand}, :cost_list).select("purchase_order_products.id, products.code, common_fields.name, cost, products.id AS product_id").each do |pop|
      purchase_return_product = @purchase_return.purchase_return_products.build purchase_order_product_id: pop.id, product_cost: pop.cost, product_code: pop.code, product_name: pop.name, product_id: pop.product_id
      pop.purchase_order_details.select(:id).each do |pod|
        purchase_return_product.purchase_return_items.build purchase_order_detail_id: pod.id
      end
    end
    respond_to { |format| format.js }
  end

  def get_direct_purchase_details
    @purchase_return = PurchaseReturn.new
    @direct_purchase_id = ReceivedPurchaseOrder.select("direct_purchase_id").where(id: params[:received_purchase_order_id]).first.direct_purchase_id
    direct_purchase = DirectPurchase.select(:id).where(id: @direct_purchase_id).first
    direct_purchase.direct_purchase_products.joins({product: :brand}, :cost_list).select("direct_purchase_products.id, products.code, common_fields.name, cost, products.id AS product_id").each do |dpp|
      purchase_return_product = @purchase_return.purchase_return_products.build direct_purchase_product_id: dpp.id, product_cost: dpp.cost, product_code: dpp.code, product_name: dpp.name, product_id: dpp.product_id
      dpp.direct_purchase_details.select(:id).each do |dpd|
        purchase_return_product.purchase_return_items.build direct_purchase_detail_id: dpd.id
      end
    end
    respond_to { |format| format.js }
  end

  private
  
  def merge_new_param_to_item_attributes
    params[:purchase_return][:purchase_return_products_attributes].each do |key, value|
      params[:purchase_return][:purchase_return_products_attributes][key][:purchase_return_items_attributes].each do |purchase_return_items_key, value|
        params[:purchase_return][:purchase_return_products_attributes][key][:purchase_return_items_attributes][purchase_return_items_key].merge! direct_purchase_return: true
      end
    end if params[:purchase_return][:purchase_return_products_attributes].present?
  end
  
  # Use callbacks to share common setup or constraints between actions.
  def set_purchase_return
    @purchase_return = PurchaseReturn.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def purchase_return_params
    params.require(:purchase_return).permit(:direct_purchase_id, :direct_purchase_return, :delivery_order_number, :number, :vendor_id, :purchase_order_id,
      purchase_return_products_attributes: [:direct_purchase_product_id, :id, :purchase_order_product_id, :product_cost, :product_code, :product_name, :product_id,
        purchase_return_items_attributes: [:direct_purchase_return, :direct_purchase_detail_id, :quantity, :purchase_order_detail_id, :id]])
  end
end
