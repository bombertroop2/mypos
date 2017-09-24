include SmartListing::Helper::ControllerExtensions
class PurchaseReturnsController < ApplicationController
  load_and_authorize_resource
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
    @vendors = Vendor.select(:id, :name).order(:name)
  end

  # GET /purchase_returns/1/edit
  def edit
  end
  
  def create_direct_purchase_return
    merge_new_param_to_item_attributes
    @purchase_return = PurchaseReturn.new(purchase_return_params)
    unless @purchase_return.save
      direct_purchase = DirectPurchase.select(:id).where(id: @purchase_return.direct_purchase_id).first
      @direct_purchase_products = direct_purchase.direct_purchase_products.joins({product: :brand}, :cost_list).includes(:direct_purchase_details, :colors, :sizes).select("direct_purchase_products.id, products.code, common_fields.name, cost, products.id AS product_id") rescue []
      @direct_purchase_details = {}
      @direct_purchase_products.each do |dpp|
        purchase_return_product = @purchase_return.purchase_return_products.select{|prp| prp.direct_purchase_product_id == dpp.id}.first
        unless purchase_return_product.present?
          purchase_return_product = @purchase_return.purchase_return_products.build direct_purchase_product_id: dpp.id, product_cost: dpp.cost, product_code: dpp.code, product_name: dpp.name, product_id: dpp.product_id
        end
        @direct_purchase_details[dpp.id] = dpp.direct_purchase_details
        @direct_purchase_details[dpp.id].each do |dpd|
          purchase_return_product.purchase_return_items.build direct_purchase_detail_id: dpd.id if purchase_return_product.purchase_return_items.select{|pri| pri.direct_purchase_detail_id.eql?(dpd.id)}.blank?
        end
      end if direct_purchase.present?

      if params[:received_date].present?
        splitted_received_date = params[:received_date].split("-")
        start_received_date = splitted_received_date[0].strip.to_date
        end_received_date = splitted_received_date[1].strip.to_date
      end
      
      @do_numbers = if params[:received_date].present? && params[:vendor_id].present?
        ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").where(["DATE(receiving_date) BETWEEN ? AND ? #{params[:query_operator].strip} vendor_id = ?", start_received_date, end_received_date, params[:vendor_id].strip]).order(:delivery_order_number)
      elsif params[:received_date].present?
        ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").where(["DATE(receiving_date) BETWEEN ? AND ?", start_received_date, end_received_date]).order(:delivery_order_number)
      elsif params[:vendor_id].present?
        ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").where(["vendor_id = ?", params[:vendor_id].strip]).order(:delivery_order_number)
      else
        ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").order(:delivery_order_number)
      end

      render js: "bootbox.alert({message: \"#{@purchase_return.errors[:base].join("\\n")}\",size: 'small'});" if @purchase_return.errors[:base].present?
    else
      @pr_number = @purchase_return.number
      @vendor_name = DirectPurchase.joins(:vendor).where(["direct_purchases.id = ?",@purchase_return.direct_purchase_id]).select("vendors.name").first.name
    end
  rescue ActiveRecord::RecordNotUnique => e
    render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
  end

  # POST /purchase_returns
  # POST /purchase_returns.json
  def create
    add_additional_params_to_child
    @purchase_return = PurchaseReturn.new(purchase_return_params)
    unless @purchase_return.save
      purchase_order = PurchaseOrder.where(id: @purchase_return.purchase_order_id).select(:id).first
      @purchase_order_products = purchase_order.purchase_order_products.joins({product: :brand}, :cost_list).includes(:purchase_order_details, :colors, :sizes).select("purchase_order_products.id, products.code, common_fields.name, cost, products.id AS product_id") rescue []
      @purchase_order_details = {}
      @purchase_order_products.each do |pop|
        purchase_return_product = @purchase_return.purchase_return_products.select{|prp| prp.purchase_order_product_id == pop.id}.first
        unless purchase_return_product.present?
          purchase_return_product = @purchase_return.purchase_return_products.build purchase_order_product_id: pop.id, product_cost: pop.cost, product_code: pop.code, product_name: pop.name, product_id: pop.product_id
        end
        @purchase_order_details[pop.id] = pop.purchase_order_details
        @purchase_order_details[pop.id].each do |pod|
          purchase_return_product.purchase_return_items.build purchase_order_detail_id: pod.id if purchase_return_product.purchase_return_items.select{|pri| pri.purchase_order_detail_id.eql?(pod.id)}.blank?
        end
      end if purchase_order

      if params[:po_date].present?
        splitted_po_date = params[:po_date].split("-")
        start_po_date = splitted_po_date[0].strip.to_date
        end_po_date = splitted_po_date[1].strip.to_date
      end
    
      @purchase_orders = if params[:po_date].present? && params[:vendor_id].present?
        PurchaseOrder.where(["status != 'Open' AND DATE(purchase_order_date) BETWEEN ? AND ? #{params[:query_operator].strip} vendor_id = ?", start_po_date, end_po_date, params[:vendor_id].strip]).select :id, :number
      elsif params[:po_date].present?
        PurchaseOrder.where(["status != 'Open' AND DATE(purchase_order_date) BETWEEN ? AND ?", start_po_date, end_po_date]).select :id, :number
      elsif params[:vendor_id].present?
        PurchaseOrder.where(["status != 'Open' AND vendor_id = ?", params[:vendor_id].strip]).select :id, :number
      else
        PurchaseOrder.where("status != 'Open'").select :id, :number
      end

      render js: "bootbox.alert({message: \"#{@purchase_return.errors[:base].join("\\n")}\",size: 'small'});" if @purchase_return.errors[:base].present?
    else
      @pr_number = @purchase_return.number
      @vendor_name = PurchaseOrder.joins(:vendor).where(["purchase_orders.id = ?",@purchase_return.purchase_order_id]).select("vendors.name").first.name
    end
  rescue ActiveRecord::RecordNotUnique => e
    render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
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
    @purchase_order_products = purchase_order.purchase_order_products.joins({product: :brand}, :cost_list).includes(:purchase_order_details, :colors, :sizes).select("purchase_order_products.id, products.code, common_fields.name, cost, products.id AS product_id")
    @purchase_order_details = {}
    @purchase_order_products.each do |pop|
      purchase_return_product = @purchase_return.purchase_return_products.build purchase_order_product_id: pop.id, product_cost: pop.cost, product_code: pop.code, product_name: pop.name, product_id: pop.product_id
      @purchase_order_details[pop.id] = pop.purchase_order_details
      @purchase_order_details[pop.id].each do |pod|
        purchase_return_product.purchase_return_items.build purchase_order_detail_id: pod.id
      end
    end
    respond_to { |format| format.js }
  end

  def get_direct_purchase_details
    @purchase_return = PurchaseReturn.new direct_purchase_return: true
    @direct_purchase_id = ReceivedPurchaseOrder.select("direct_purchase_id").where(id: params[:received_purchase_order_id]).first.direct_purchase_id
    direct_purchase = DirectPurchase.select(:id).where(id: @direct_purchase_id).first
    @direct_purchase_products = direct_purchase.direct_purchase_products.joins({product: :brand}, :cost_list).includes(:direct_purchase_details, :colors, :sizes).select("direct_purchase_products.id, products.code, common_fields.name, cost, products.id AS product_id")
    @direct_purchase_details = {}
    @direct_purchase_products.each do |dpp|
      purchase_return_product = @purchase_return.purchase_return_products.build direct_purchase_product_id: dpp.id, product_cost: dpp.cost, product_code: dpp.code, product_name: dpp.name, product_id: dpp.product_id
      @direct_purchase_details[dpp.id] = dpp.direct_purchase_details
      @direct_purchase_details[dpp.id].each do |dpd|
        purchase_return_product.purchase_return_items.build direct_purchase_detail_id: dpd.id
      end
    end
    respond_to { |format| format.js }
  end
  
  def filter_purchase_records
    @purchase_return = unless params[:type].present?
      PurchaseReturn.new
    else
      PurchaseReturn.new direct_purchase_return: true
    end

    unless params[:type].present?
      if params[:po_date].present?
        splitted_po_date = params[:po_date].split("-")
        start_po_date = splitted_po_date[0].strip.to_date
        end_po_date = splitted_po_date[1].strip.to_date
      end

      @purchase_orders = if params[:po_date].present? && params[:vendor_id].present?
        PurchaseOrder.where(["status != 'Open' AND DATE(purchase_order_date) BETWEEN ? AND ? #{params[:query_operator].strip} vendor_id = ?", start_po_date, end_po_date, params[:vendor_id].strip]).select :id, :number
      elsif params[:po_date].present?
        PurchaseOrder.where(["status != 'Open' AND DATE(purchase_order_date) BETWEEN ? AND ?", start_po_date, end_po_date]).select :id, :number
      elsif params[:vendor_id].present?
        PurchaseOrder.where(["status != 'Open' AND vendor_id = ?", params[:vendor_id].strip]).select :id, :number
      elsif params[:po_number].present?
        PurchaseOrder.where(["status != 'Open' AND number = ?", params[:po_number]]).select :id, :number
      else
        PurchaseOrder.where("status != 'Open'").select :id, :number
      end
    
      if @purchase_orders.blank? && params[:po_number].present?
        render js: "bootbox.alert({message: \"No records found\",size: 'small'});"
      elsif params[:po_number].present?
        purchase_order = @purchase_orders.first
        @purchase_return.purchase_order_id = purchase_order.id
        @purchase_order_products = purchase_order.purchase_order_products.joins({product: :brand}, :cost_list).includes(:purchase_order_details, :colors, :sizes).select("purchase_order_products.id, products.code, common_fields.name, cost, products.id AS product_id")
        @purchase_order_details = {}
        @purchase_order_products.each do |pop|
          purchase_return_product = @purchase_return.purchase_return_products.build purchase_order_product_id: pop.id, product_cost: pop.cost, product_code: pop.code, product_name: pop.name, product_id: pop.product_id
          @purchase_order_details[pop.id] = pop.purchase_order_details
          @purchase_order_details[pop.id].each do |pod|
            purchase_return_product.purchase_return_items.build purchase_order_detail_id: pod.id
          end
        end
      end
    else
      if params[:received_date].present?
        splitted_received_date = params[:received_date].split("-")
        start_received_date = splitted_received_date[0].strip.to_date
        end_received_date = splitted_received_date[1].strip.to_date
      end
      
      @do_numbers = if params[:received_date].present? && params[:vendor_id].present?
        ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").where(["DATE(receiving_date) BETWEEN ? AND ? #{params[:query_operator].strip} vendor_id = ?", start_received_date, end_received_date, params[:vendor_id].strip]).order(:delivery_order_number)
      elsif params[:received_date].present?
        ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").where(["DATE(receiving_date) BETWEEN ? AND ?", start_received_date, end_received_date]).order(:delivery_order_number)
      elsif params[:vendor_id].present?
        ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").where(["vendor_id = ?", params[:vendor_id].strip]).order(:delivery_order_number)
      elsif params[:do_number].present?
        ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id, direct_purchase_id").where(["delivery_order_number = ?", params[:do_number]]).order(:delivery_order_number)
      else
        ReceivedPurchaseOrder.joins(:direct_purchase).select("delivery_order_number, received_purchase_orders.id").order(:delivery_order_number)
      end

      if @do_numbers.blank? && params[:do_number].present?
        render js: "bootbox.alert({message: \"No records found\",size: 'small'});"
      elsif params[:do_number].present?
        @direct_purchase_id = @do_numbers.first.direct_purchase_id
        direct_purchase = DirectPurchase.select(:id).where(id: @direct_purchase_id).first
        @purchase_return.direct_purchase_id = @direct_purchase_id
        @purchase_return.delivery_order_number = params[:do_number]
        @direct_purchase_products = direct_purchase.direct_purchase_products.joins({product: :brand}, :cost_list).includes(:direct_purchase_details, :colors, :sizes).select("direct_purchase_products.id, products.code, common_fields.name, cost, products.id AS product_id")
        @direct_purchase_details = {}
        @direct_purchase_products.each do |dpp|
          purchase_return_product = @purchase_return.purchase_return_products.build direct_purchase_product_id: dpp.id, product_cost: dpp.cost, product_code: dpp.code, product_name: dpp.name, product_id: dpp.product_id
          @direct_purchase_details[dpp.id] = dpp.direct_purchase_details
          @direct_purchase_details[dpp.id].each do |dpd|
            purchase_return_product.purchase_return_items.build direct_purchase_detail_id: dpd.id
          end
        end
      end
    end
    
    
  end

  private
  
  def merge_new_param_to_item_attributes
    params[:purchase_return][:purchase_return_products_attributes].each do |key, value|
      params[:purchase_return][:purchase_return_products_attributes][key].merge! returning_direct_purchase: true, direct_purchase_id: params[:purchase_return][:direct_purchase_id]
      direct_purchase_product_id = params[:purchase_return][:purchase_return_products_attributes][key][:direct_purchase_product_id]
      params[:purchase_return][:purchase_return_products_attributes][key][:purchase_return_items_attributes].each do |purchase_return_items_key, value|
        params[:purchase_return][:purchase_return_products_attributes][key][:purchase_return_items_attributes][purchase_return_items_key].merge! direct_purchase_return: true, direct_purchase_id: params[:purchase_return][:direct_purchase_id], direct_purchase_product_id: direct_purchase_product_id
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
      purchase_return_products_attributes: [:direct_purchase_id, :returning_direct_purchase, :purchase_order_id, :direct_purchase_product_id, :id, :purchase_order_product_id, :product_cost, :product_code, :product_name, :product_id,
        purchase_return_items_attributes: [:direct_purchase_id, :direct_purchase_product_id, :purchase_order_product_id, :purchase_order_id, :direct_purchase_return, :direct_purchase_detail_id, :quantity, :purchase_order_detail_id, :id]])
  end
  
  def add_additional_params_to_child
    params[:purchase_return][:purchase_return_products_attributes].each do |key, value|
      params[:purchase_return][:purchase_return_products_attributes][key].merge! purchase_order_id: params[:purchase_return][:purchase_order_id]
      purchase_order_product_id = params[:purchase_return][:purchase_return_products_attributes][key][:purchase_order_product_id]
      params[:purchase_return][:purchase_return_products_attributes][key][:purchase_return_items_attributes].each do |pri_key, value|
        params[:purchase_return][:purchase_return_products_attributes][key][:purchase_return_items_attributes][pri_key].merge! purchase_order_product_id: purchase_order_product_id, purchase_order_id: params[:purchase_return][:purchase_order_id]
      end if params[:purchase_return][:purchase_return_products_attributes][key][:purchase_return_items_attributes].present?
    end if params[:purchase_return][:purchase_return_products_attributes].present?
  end
end
