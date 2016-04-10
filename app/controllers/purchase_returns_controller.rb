class PurchaseReturnsController < ApplicationController
  before_action :set_purchase_return, only: [:show, :edit, :update, :destroy]

  # GET /purchase_returns
  # GET /purchase_returns.json
  def index
    @purchase_returns = PurchaseReturn.all
  end

  # GET /purchase_returns/1
  # GET /purchase_returns/1.json
  def show
  end

  # GET /purchase_returns/new
  def new
    @purchase_return = PurchaseReturn.new
    @purchase_orders = PurchaseOrder.where("status != 'Open' AND status != 'Deleted'")
  end

  # GET /purchase_returns/1/edit
  def edit
  end

  # POST /purchase_returns
  # POST /purchase_returns.json
  def create
    @purchase_return = PurchaseReturn.new(purchase_return_params)
    is_exception_raised = false
    respond_to do |format|
      begin
        if @purchase_return.save
          format.html { redirect_to @purchase_return, notice: 'Purchase return was successfully created.' }
          format.json { render :show, status: :created, location: @purchase_return }
        else
          @purchase_return.purchase_return_products.each do |prp|
            prp.purchase_order_product.purchase_order_details.each do |pod|
              prp.purchase_return_items.build purchase_order_detail_id: pod.id if prp.purchase_return_items.select{|pri| pri.purchase_order_detail.eql?(pod)}.blank?
            end
          end
          @purchase_orders = PurchaseOrder.all
          if @purchase_return.errors[:base].present?
            flash.now[:alert] = @purchase_return.errors[:base].to_sentence
          end
          format.html { render :new }
          format.json { render json: @purchase_return.errors, status: :unprocessable_entity }
        end
        is_exception_raised = false
      rescue ActiveRecord::RecordNotUnique => e
        is_exception_raised = true
      end while is_exception_raised
    end
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
    purchase_order = PurchaseOrder.find params[:purchase_order_id]
    purchase_order.purchase_order_products.each do |pop|
      purchase_return_product = @purchase_return.purchase_return_products.build purchase_order_product_id: pop.id
      pop.purchase_order_details.each do |pod|
        purchase_return_product.purchase_return_items.build purchase_order_detail_id: pod.id
      end
    end
    respond_to { |format| format.js }
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_purchase_return
    @purchase_return = PurchaseReturn.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def purchase_return_params
    params.require(:purchase_return).permit(:number, :vendor_id, :purchase_order_id,
      purchase_return_products_attributes: [:id, :purchase_order_product_id,
        purchase_return_items_attributes: [:quantity, :purchase_order_detail_id, :id]])
  end
end
