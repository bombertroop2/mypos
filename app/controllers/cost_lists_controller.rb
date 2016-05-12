class CostListsController < ApplicationController
  before_action :set_cost_list, only: [:show, :edit, :update, :destroy]
  before_action :convert_cost_to_numeric, only: [:create, :update]
  before_action :get_products, only: [:new, :edit]

  # GET /cost_lists
  # GET /cost_lists.json
  def index
    @cost_lists = CostList.joins(:product).select("cost_lists.id, effective_date, cost, code")
  end

  # GET /cost_lists/1
  # GET /cost_lists/1.json
  def show
  end

  # GET /cost_lists/new
  def new
    @cost_list = CostList.new
  end

  # GET /cost_lists/1/edit
  def edit
    @cost_list.effective_date = @cost_list.effective_date.strftime("%d/%m/%Y")
  end

  # POST /cost_lists
  # POST /cost_lists.json
  def create
    @cost_list = CostList.new(cost_list_params)

    respond_to do |format|
      begin
        if @cost_list.save
          format.html { redirect_to cost_lists_url, notice: 'Cost was successfully created.' }
          format.json { render :show, status: :created, location: @cost_list }
        else
          @products = Product.joins(:brand, :model, :goods_type, :vendor).select("products.id, products.code as products_code, common_fields.name, models_products.name as models_products_name, goods_types_products.name as goods_types_products_name, vendors.name as vendors_name, target")
          format.html { render :new }
          format.json { render json: @cost_list.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @products = Product.joins(:brand, :model, :goods_type, :vendor).select("products.id, products.code as products_code, common_fields.name, models_products.name as models_products_name, goods_types_products.name as goods_types_products_name, vendors.name as vendors_name, target")
        @cost_list.errors.messages[:effective_date] = ["has already been taken"]
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /cost_lists/1
  # PATCH/PUT /cost_lists/1.json
  def update
    respond_to do |format|
      begin
        if @cost_list.update(cost_list_params)
          format.html { redirect_to cost_lists_url, notice: 'Cost was successfully updated.' }
          format.json { render :show, status: :ok, location: @cost_list }
        else
          @products = Product.joins(:brand, :model, :goods_type, :vendor).select("products.id, products.code as products_code, common_fields.name, models_products.name as models_products_name, goods_types_products.name as goods_types_products_name, vendors.name as vendors_name, target")
          format.html { render :edit }
          format.json { render json: @cost_list.errors, status: :unprocessable_entity }
        end
      rescue ActiveRecord::RecordNotUnique => e
        @products = Product.joins(:brand, :model, :goods_type, :vendor).select("products.id, products.code as products_code, common_fields.name, models_products.name as models_products_name, goods_types_products.name as goods_types_products_name, vendors.name as vendors_name, target")
        @cost_list.errors.messages[:effective_date] = ["has already been taken"]
        format.html { render :edit }
      end
    end
  end

  # DELETE /cost_lists/1
  # DELETE /cost_lists/1.json
  def destroy
    @cost_list.user_is_deleting_from_child = true
    unless @cost_list.destroy
      error_message = @cost_list.errors.messages[:base].to_sentence
      error_message.slice! "products "
      alert = error_message
    else
      notice = "Cost was successfully deleted."
    end
    respond_to do |format|
      format.html do 
        if notice.present?
          redirect_to cost_lists_url, notice: notice
        else
          redirect_to cost_lists_url, alert: alert
        end
      end
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_cost_list
    @cost_list = CostList.where(id: params[:id]).select(:id, :product_id, :effective_date, :cost).first
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def cost_list_params
    params.require(:cost_list).permit(:product_id, :effective_date, :cost)
  end
  
  def convert_cost_to_numeric
    params[:cost_list][:cost] = params[:cost_list][:cost].gsub("Rp","").gsub(".","").gsub(",",".")
  end
  
  def get_products
    @products = Product.joins(:brand, :model, :goods_type, :vendor).select("products.id, products.code as products_code, common_fields.name, models_products.name as models_products_name, goods_types_products.name as goods_types_products_name, vendors.name as vendors_name, target")
  end
end
