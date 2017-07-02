include SmartListing::Helper::ControllerExtensions
class StockMutationsController < ApplicationController
  load_and_authorize_resource
  helper SmartListing::Helper
  before_action :set_stock_mutation, only: [:show, :show_store_mutation]

  # GET /stock_mutations
  # GET /stock_mutations.json
  def index
    like_command = if Rails.env.eql?("production")
      "ILIKE"
    else
      "LIKE"
    end
    if params[:filter_delivery_date].present?
      splitted_delivery_date_range = params[:filter_delivery_date].split("-")
      start_delivery_date = splitted_delivery_date_range[0].strip.to_date
      end_delivery_date = splitted_delivery_date_range[1].strip.to_date
    end
    if params[:filter_received_date].present?
      splitted_received_date_range = params[:filter_received_date].split("-")
      start_received_date = splitted_received_date_range[0].strip.to_date
      end_received_date = splitted_received_date_range[1].strip.to_date
    end
    stock_mutations_scope = StockMutation.select(:id, :number, :delivery_date, :received_date, :quantity)
    stock_mutations_scope = stock_mutations_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(stock_mutations_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(received_date) BETWEEN ? AND ?", start_received_date, end_received_date]) if params[:filter_received_date].present?
    #    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @stock_mutations = smart_listing_create(:stock_mutations, stock_mutations_scope, partial: 'stock_mutations/listing', default_sort: {number: "asc"})
  end

  def index_store_mutation
  end

  # GET /stock_mutations/1
  # GET /stock_mutations/1.json
  def show
  end

  # GET /stock_mutations/1
  # GET /stock_mutations/1.json
  def show_store_mutation
  end

  # GET /stock_mutations/new
  def new
    @origin_warehouses = Warehouse.not_central.select(:id, :code)
  end

  # POST /stock_mutations
  # POST /stock_mutations.json
  def create
    add_additional_params
    @stock_mutation = StockMutation.new(stock_mutation_params)
    @stock_mutation.quantity = @total_stock_mutation_quantity
    begin
      unless @saved = @stock_mutation.save
        if @stock_mutation.errors[:"stock_mutation_products.base"].present?
          render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.base"].join("<br/>")}\",size: 'small'});"
        elsif @stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].present?
          render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].join("<br/>")}\",size: 'small'});"
        else
          @destintation_warehouses = Warehouse.not_central.where(["id <> ?", params[:stock_mutation][:origin_warehouse_id]]).select(:id, :code)
          @colors = []
          @sizes = []
          @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
            stock_product = StockProduct.joins(:stock).where(product_id: stock_mutation_product.product_id).where(["warehouse_id = ?", params[:stock_mutation][:origin_warehouse_id]]).first
            @colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
            @sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
            @colors[stock_mutation_product.product_id].each do |color|
              @sizes[stock_mutation_product.product_id].each do |size|
                stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.select{|smpi| smpi.color_id == color.id && smpi.size_id == size.id}.blank?
              end
            end        
          end
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
    end
  end

  # GET /stock_mutations/new
  def new_store_mutation
    @origin_warehouses = Warehouse.not_central.select(:id, :code)
  end

  # POST /stock_mutations
  # POST /stock_mutations.json
  def create_store_mutation
    add_additional_params
    @stock_mutation = StockMutation.new(stock_mutation_params)
    @stock_mutation.quantity = @total_stock_mutation_quantity
    begin
      unless @saved = @stock_mutation.save
        if @stock_mutation.errors[:"stock_mutation_products.base"].present?
          render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.base"].join("<br/>")}\",size: 'small'});"
        elsif @stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].present?
          render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].join("<br/>")}\",size: 'small'});"
        else
          @destintation_warehouses = Warehouse.not_central.where(["id <> ?", params[:stock_mutation][:origin_warehouse_id]]).select(:id, :code)
          @colors = []
          @sizes = []
          @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
            stock_product = StockProduct.joins(:stock).where(product_id: stock_mutation_product.product_id).where(["warehouse_id = ?", params[:stock_mutation][:origin_warehouse_id]]).first
            @colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
            @sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
            @colors[stock_mutation_product.product_id].each do |color|
              @sizes[stock_mutation_product.product_id].each do |size|
                stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.select{|smpi| smpi.color_id == color.id && smpi.size_id == size.id}.blank?
              end
            end        
          end
        end
      end
    rescue ActiveRecord::RecordNotUnique => e
      render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
    end
  end

  def get_products
    @products = Product.joins(:brand).joins(stock_products: :stock).where(["warehouse_id = ?", params[:warehouse_id]]).select(:id, :code, :name).order(:code)
  end

  def generate_form
    selected_product_ids = params[:product_ids]
    @destintation_warehouses = Warehouse.not_central.where(["id <> ?", params[:warehouse_id]]).select(:id, :code)
    @stock_mutation = StockMutation.new origin_warehouse_id: params[:warehouse_id]
    products = Product.where(id: params[:product_ids].split(",")).select(:id)
    @colors = []
    @sizes = []
    products.each do |product|
      stock_mutation_product = @stock_mutation.stock_mutation_products.build product_id: product.id
      stock_product = StockProduct.joins(:stock).where(product_id: product.id).where(["warehouse_id = ?", params[:warehouse_id]]).first
      @colors[product.id] = stock_product.colors.select(:id, :code, :name)
      @sizes[product.id] = stock_product.sizes.select(:id, :size)
      @colors[product.id].each do |color|
        @sizes[product.id].each do |size|
          stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id
        end
      end        
    end
  end

  def generate_store_mutation_form
    selected_product_ids = params[:product_ids]
    @destintation_warehouses = Warehouse.not_central.where(["id <> ?", params[:warehouse_id]]).select(:id, :code)
    @stock_mutation = StockMutation.new origin_warehouse_id: params[:warehouse_id]
    products = Product.where(id: params[:product_ids].split(",")).select(:id)
    @colors = []
    @sizes = []
    products.each do |product|
      stock_mutation_product = @stock_mutation.stock_mutation_products.build product_id: product.id
      stock_product = StockProduct.joins(:stock).where(product_id: product.id).where(["warehouse_id = ?", params[:warehouse_id]]).first
      @colors[product.id] = stock_product.colors.select(:id, :code, :name)
      @sizes[product.id] = stock_product.sizes.select(:id, :size)
      @colors[product.id].each do |color|
        @sizes[product.id].each do |size|
          stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id
        end
      end        
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_stock_mutation
    @stock_mutation = StockMutation.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def stock_mutation_params
    params.require(:stock_mutation).permit(:delivery_date, :received_date, :quantity, :courier_id, :origin_warehouse_id, :number, :destination_warehouse_id,
      stock_mutation_products_attributes: [:quantity, :origin_warehouse_id, :product_id, stock_mutation_product_items_attributes: [:color_id, :size_id, :quantity, :origin_warehouse_id, :product_id]])
  end
  
  def add_additional_params
    @total_stock_mutation_quantity = 0
    params[:stock_mutation][:stock_mutation_products_attributes].each do |key, value|
      total_stock_mutation_product_quantity = 0
      params[:stock_mutation][:stock_mutation_products_attributes][key].merge! origin_warehouse_id: params[:stock_mutation][:origin_warehouse_id]
      params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes].each do |smpi_key, smpi_value|
        @total_stock_mutation_quantity += params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key][:quantity].to_i
        total_stock_mutation_product_quantity += params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key][:quantity].to_i
        params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key].merge! origin_warehouse_id: params[:stock_mutation][:origin_warehouse_id], product_id: params[:stock_mutation][:stock_mutation_products_attributes][key][:product_id]
      end if params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes].present?
      params[:stock_mutation][:stock_mutation_products_attributes][key][:quantity] = total_stock_mutation_product_quantity
    end if params[:stock_mutation][:stock_mutation_products_attributes].present?
  end
end
