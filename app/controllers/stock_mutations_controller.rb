include SmartListing::Helper::ControllerExtensions
class StockMutationsController < ApplicationController
  load_and_authorize_resource
  helper SmartListing::Helper
  before_action :set_stock_mutation, only: [:show, :show_store_to_warehouse_mutation, :edit,
    :update, :destroy, :edit_store_to_warehouse, :update_store_to_warehouse,
    :delete_store_to_warehouse, :approve]

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
    if params[:filter_approved_date].present?
      splitted_approved_date_range = params[:filter_approved_date].split("-")
      start_approved_date = splitted_approved_date_range[0].strip.to_date
      end_approved_date = splitted_approved_date_range[1].strip.to_date
    end
    if params[:filter_received_date].present?
      splitted_received_date_range = params[:filter_received_date].split("-")
      start_received_date = splitted_received_date_range[0].strip.to_date
      end_received_date = splitted_received_date_range[1].strip.to_date
    end
    stock_mutations_scope = if current_user.has_non_spg_role?
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :received_date, :quantity,
        :destination_warehouse_id, :approved_date).
        where("warehouse_type <> 'central'")
    else
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :received_date, :quantity,
        :destination_warehouse_id, :approved_date).
        where("warehouse_type <> 'central' AND origin_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}")
    end
    stock_mutations_scope = stock_mutations_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(stock_mutations_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(received_date) BETWEEN ? AND ?", start_received_date, end_received_date]) if params[:filter_received_date].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(approved_date) BETWEEN ? AND ?", start_approved_date, end_approved_date]) if params[:filter_approved_date].present?
    #    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @stock_mutations = smart_listing_create(:stock_mutations, stock_mutations_scope, partial: 'stock_mutations/listing', default_sort: {number: "asc"})
  end
  
  def store_to_store_inventory_receipts
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
    if params[:filter_approved_date].present?
      splitted_approved_date_range = params[:filter_approved_date].split("-")
      start_approved_date = splitted_approved_date_range[0].strip.to_date
      end_approved_date = splitted_approved_date_range[1].strip.to_date
    end
    if params[:filter_received_date].present?
      splitted_received_date_range = params[:filter_received_date].split("-")
      start_received_date = splitted_received_date_range[0].strip.to_date
      end_received_date = splitted_received_date_range[1].strip.to_date
    end
    stock_mutations_scope = if current_user.has_non_spg_role?
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :received_date, :quantity,
        :destination_warehouse_id, :approved_date).
        where("warehouse_type <> 'central'")
    else
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :received_date, :quantity,
        :destination_warehouse_id, :approved_date).
        where("warehouse_type <> 'central' AND destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}")
    end
    stock_mutations_scope = stock_mutations_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(stock_mutations_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(received_date) BETWEEN ? AND ?", start_received_date, end_received_date]) if params[:filter_received_date].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(approved_date) BETWEEN ? AND ?", start_approved_date, end_approved_date]) if params[:filter_approved_date].present?
    #    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @stock_mutations = smart_listing_create(:stock_mutations, stock_mutations_scope, partial: 'stock_mutations/listing_store_to_store_inventory_receipts', default_sort: {number: "asc"})
  end
  
  def store_to_warehouse_inventory_receipts
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
    stock_mutations_scope = StockMutation.joins(:destination_warehouse).
      select(:id, :number, :delivery_date, :received_date, :quantity,
      :destination_warehouse_id).
      where("warehouse_type = 'central'")
    stock_mutations_scope = stock_mutations_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(stock_mutations_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(received_date) BETWEEN ? AND ?", start_received_date, end_received_date]) if params[:filter_received_date].present?
    #    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @stock_mutations = smart_listing_create(:stock_mutations, stock_mutations_scope, partial: 'stock_mutations/listing_store_to_warehouse_inventory_receipts', default_sort: {number: "asc"})
  end

  def index_store_to_warehouse_mutation
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
    stock_mutations_scope = if current_user.has_non_spg_role?
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :received_date, :quantity,
        :destination_warehouse_id, :approved_date).
        where("warehouse_type = 'central'")
    else
      StockMutation.joins(:destination_warehouse).
        select(:id, :number, :delivery_date, :received_date, :quantity,
        :destination_warehouse_id, :approved_date).
        where("warehouse_type = 'central' AND origin_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}")
    end
    stock_mutations_scope = stock_mutations_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"]).
      or(stock_mutations_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(delivery_date) BETWEEN ? AND ?", start_delivery_date, end_delivery_date]) if params[:filter_delivery_date].present?
    stock_mutations_scope = stock_mutations_scope.where(["DATE(received_date) BETWEEN ? AND ?", start_received_date, end_received_date]) if params[:filter_received_date].present?
    #    shipments_scope = shipments_scope.where(["destination_warehouse_id = ?", params[:filter_destination_warehouse]]) if params[:filter_destination_warehouse].present?
    @stock_mutations = smart_listing_create(:stock_mutations, stock_mutations_scope, partial: 'stock_mutations/listing_store_to_warehouse_mutation', default_sort: {number: "asc"})
  end

  # GET /stock_mutations/1
  # GET /stock_mutations/1.json
  def show
  end
  
  def show_store_to_store_receipt
    @stock_mutation = if current_user.has_non_spg_role?
      StockMutation.joins(:destination_warehouse).
        select("stock_mutations.*").
        where("warehouse_type <> 'central'").where(id: params[:id]).first
    else
      StockMutation.joins(:destination_warehouse).
        select("stock_mutations.*").
        where("warehouse_type <> 'central' AND destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
        where(id: params[:id]).first
    end
  end

  def show_store_to_warehouse_receipt
    @stock_mutation = StockMutation.joins(:destination_warehouse).
      select("stock_mutations.*").
      where("warehouse_type = 'central'").where(id: params[:id]).first
  end

  # GET /stock_mutations/1
  # GET /stock_mutations/1.json
  def show_store_to_warehouse_mutation
  end

  # GET /stock_mutations/new
  def new
    @origin_warehouses = @destintation_warehouses = Warehouse.not_central.select(:id, :code)
    @stock_mutation = StockMutation.new
  end

  # POST /stock_mutations
  # POST /stock_mutations.json
  def create
    add_additional_params("store to store")
    if @valid
      @stock_mutation = StockMutation.new(stock_mutation_params)
      @stock_mutation.quantity = @total_stock_mutation_quantity
      begin
        unless @saved = @stock_mutation.save
          if @stock_mutation.errors[:"stock_mutation_products.base"].present?
            render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.base"].join("<br/>")}\",size: 'small'});"
          elsif @stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].present?
            render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].join("<br/>")}\",size: 'small'});"
          else
            @origin_warehouses = @destintation_warehouses = Warehouse.not_central.select(:id, :code)
            selected_product_ids = @stock_mutation.stock_mutation_products.map(&:product_id)
            @selected_products = Product.joins(stock_products: :stock).
              where(id: selected_product_ids).
              where(["stocks.warehouse_id = ?", @stock_mutation.origin_warehouse_id]).
              select(:id).select("stock_products.id AS stock_product_id")
            stock_products = if @selected_products.length > 1
              StockProduct.joins(:stock).includes(:colors, :sizes).where(product_id: @selected_products.pluck(:id)).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).select(:id, :product_id)
            else
              StockProduct.joins(:stock).where(product_id: @selected_products.pluck(:id)).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).select(:id, :product_id)
            end
            @stock_mutation_products = []
            @product_colors = {}
            @product_sizes = {}
            @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
              stock_product = stock_products.select{|sp| sp.product_id == stock_mutation_product.product_id}.first

              if stock_products.length > 1
                @product_colors[stock_mutation_product.product_id] = stock_product.colors.distinct
                @product_sizes[stock_mutation_product.product_id] = stock_product.sizes.distinct
              else
                @product_colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
                @product_sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
              end
              @product_colors[stock_mutation_product.product_id].each do |color|
                @product_sizes[stock_mutation_product.product_id].each do |size|
                  stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.select{|smpi| smpi.color_id == color.id && smpi.size_id == size.id}.blank?
                end
              end        
              @stock_mutation_products << stock_mutation_product
            end


            #          @colors = []
            #          @sizes = []
            #          @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
            #            stock_product = StockProduct.joins(:stock).where(product_id: stock_mutation_product.product_id).where(["warehouse_id = ?", params[:stock_mutation][:origin_warehouse_id]]).first
            #            @colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
            #            @sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
            #            @colors[stock_mutation_product.product_id].each do |color|
            #              @sizes[stock_mutation_product.product_id].each do |size|
            #                stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.select{|smpi| smpi.color_id == color.id && smpi.size_id == size.id}.blank?
            #              end
            #            end        
            #          end
          end
        end
      rescue ActiveRecord::RecordNotUnique => e
        render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
      end
    else
      render js: "bootbox.alert({message: \"#{@error_message}\",size: 'small'});"
    end
  end

  # GET /stock_mutations/new
  def new_store_to_warehouse_mutation
    if current_user.has_non_spg_role?
      @origin_warehouses = Warehouse.not_central.select(:id, :code)
    else
      @products = Product.joins(:brand).joins(stock_products: :stock).where(["warehouse_id = ?", current_user.sales_promotion_girl.warehouse_id]).select(:id, :code, :name).order(:code)
      @mutation_type = "store to warehouse"
    end
  end

  # POST /stock_mutations
  # POST /stock_mutations.json
  def create_store_to_warehouse_mutation
    add_additional_params("store to warehouse")
    @stock_mutation = StockMutation.new(stock_mutation_params)
    @stock_mutation.quantity = @total_stock_mutation_quantity
    @stock_mutation.mutation_type = "store to warehouse"
    begin
      unless @saved = @stock_mutation.save
        if @stock_mutation.errors[:"stock_mutation_products.base"].present?
          render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.base"].join("<br/>")}\",size: 'small'});"
        elsif @stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].present?
          render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].join("<br/>")}\",size: 'small'});"
        else
          @destintation_warehouses = Warehouse.central.where(["id <> ?", params[:stock_mutation][:origin_warehouse_id]]).select(:id, :code)
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
    rescue RuntimeError => e
      render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
    end
  end
  
  def get_saved_products
    @stock_mutation = StockMutation.select(:id, :origin_warehouse_id).where(id: params[:stock_mutation_id]).first
    if @stock_mutation.origin_warehouse_id.to_s.eql?(params[:origin_warehouse_id])
      @stock_mutation_products = []
      @product_colors = {}
      @product_sizes = {}
      stock_mutation_products = @stock_mutation.stock_mutation_products.joins(product: :brand).select("stock_mutation_products.id, product_id, products.code, common_fields.name AS brand_name")
      stock_mutation_products.each do |stock_mutation_product|
        stock_product = StockProduct.joins(:stock).where(product_id: stock_mutation_product.product_id).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).select(:id).first
        @product_colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
        @product_sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
        @product_colors[stock_mutation_product.product_id].each do |color|
          @product_sizes[stock_mutation_product.product_id].each do |size|
            stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.where(color_id: color.id, size_id: size.id).select("1 AS one").blank?
          end
        end        
        @stock_mutation_products << stock_mutation_product
      end
    end
  end

  def get_products
    #    @products = Product.joins(:brand).joins(stock_products: :stock).where(["warehouse_id = ?", params[:warehouse_id]]).select(:id, :code, :name).order(:code)
    #    @mutation_type = params[:mutation_type]
    @stock_mutation = if params[:stock_mutation_id].present?
      StockMutation.select(:id, :origin_warehouse_id).where(id: params[:stock_mutation_id]).first
    else
      StockMutation.new
    end
    
    @selected_products = if params[:prev_selected_product_ids].present?
      Product.joins(stock_products: :stock).joins(:brand).
        where(code: params[:product_code]).
        where(["stocks.warehouse_id = ?", params[:origin_warehouse_id]]).
        where(["products.id NOT IN (?)", params[:prev_selected_product_ids].split(",")]).
        select("products.id, products.code, stock_products.id AS stock_product_id, common_fields.name AS brand_name")
    else
      Product.joins(stock_products: :stock).joins(:brand).
        where(code: params[:product_code]).
        where(["stocks.warehouse_id = ?", params[:origin_warehouse_id]]).
        select("products.id, products.code, stock_products.id AS stock_product_id, common_fields.name AS brand_name")
    end

    if @selected_products.present?
      @stock_mutation_products = []
      @product_colors = {}
      @product_sizes = {}
      @selected_products.each do |product|
        stock_product = StockProduct.joins(:stock).where(product_id: product.id).where(["warehouse_id = ?", params[:origin_warehouse_id]]).first
        @product_colors[product.id] = stock_product.colors.select(:id, :code, :name)
        @product_sizes[product.id] = stock_product.sizes.select(:id, :size)
        if (smp = @stock_mutation.stock_mutation_products.where(product_id: product.id).first).blank?
          smp = @stock_mutation.stock_mutation_products.build product_id: product.id, product_code: product.code, product_name: product.brand_name
        elsif @stock_mutation.origin_warehouse_id == params[:origin_warehouse_id].to_i
          smp.product_code = product.code
          smp.product_name = product.brand_name
        else
          smp = @stock_mutation.stock_mutation_products.build product_id: product.id, product_code: product.code, product_name: product.brand_name
        end
        @product_colors[product.id].each do |color|
          @product_sizes[product.id].each do |size|
            smp.stock_mutation_product_items.build size_id: size.id, color_id: color.id if smp.stock_mutation_product_items.select{|smpi| smpi.size_id == size.id && smpi.color_id == color.id}.blank?
          end
        end        
        @stock_mutation_products << smp
      end
    else
      render js: "bootbox.alert({message: \"No records found or already added to the list\",size: 'small'});"
    end
  end

  def generate_form
    selected_product_ids = params[:product_ids]
    @destintation_warehouses = unless params[:mutation_type].eql?("store to warehouse")
      Warehouse.not_central.where(["id <> ?", params[:warehouse_id]]).select(:id, :code)
    else
      Warehouse.central.where(["id <> ?", params[:warehouse_id]]).select(:id, :code)
    end
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
  
  def edit
    @origin_warehouses = @destintation_warehouses = Warehouse.not_central.select(:id, :code)
    @stock_mutation.delivery_date = @stock_mutation.delivery_date.strftime("%d/%m/%Y")
    selected_product_ids = @stock_mutation.stock_mutation_products.map(&:product_id)
    @selected_products = Product.joins([stock_products: :stock], :brand).
      where(id: selected_product_ids).
      where(["stocks.warehouse_id = ?", @stock_mutation.origin_warehouse_id]).
      select(:id).select("products.code, common_fields.name AS brand_name").
      select("stock_products.id AS stock_product_id")
    stock_products = if @selected_products.length > 1
      StockProduct.joins(:stock).includes(:colors, :sizes).where(product_id: @selected_products.pluck(:id)).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).select(:id, :product_id)
    else
      StockProduct.joins(:stock).where(product_id: @selected_products.pluck(:id)).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).select(:id, :product_id)
    end
    @stock_mutation_products = []
    @product_colors = {}
    @product_sizes = {}
    @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
      stock_product = stock_products.select{|sp| sp.product_id == stock_mutation_product.product_id}.first

      if stock_products.length > 1
        @product_colors[stock_mutation_product.product_id] = stock_product.colors.distinct
        @product_sizes[stock_mutation_product.product_id] = stock_product.sizes.distinct
      else
        @product_colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
        @product_sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
      end
      @product_colors[stock_mutation_product.product_id].each do |color|
        @product_sizes[stock_mutation_product.product_id].each do |size|
          stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.where(color_id: color.id, size_id: size.id).select("1 AS one").blank?
        end
      end        
      @stock_mutation_products << stock_mutation_product
    end
    #    @destintation_warehouses = Warehouse.not_central.where(["id <> ?", @stock_mutation.origin_warehouse_id]).select(:id, :code)
    #    @stock_mutation.delivery_date = @stock_mutation.delivery_date.strftime("%d/%m/%Y")
    #    @colors = []
    #    @sizes = []
    #    @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
    #      stock_product = StockProduct.joins(:stock).where(product_id: stock_mutation_product.product_id).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).first
    #      @colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
    #      @sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
    #      @colors[stock_mutation_product.product_id].each do |color|
    #        @sizes[stock_mutation_product.product_id].each do |size|
    #          stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.where(size_id: size.id, color_id: color.id).select("1 AS one").blank?
    #        end
    #      end        
    #    end
  end

  #  def edit_store_to_warehouse
  #    @destintation_warehouses = Warehouse.central.where(["id <> ?", @stock_mutation.origin_warehouse_id]).select(:id, :code)
  #    @stock_mutation.delivery_date = @stock_mutation.delivery_date.strftime("%d/%m/%Y")
  #    @colors = []
  #    @sizes = []
  #    @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
  #      stock_product = StockProduct.joins(:stock).where(product_id: stock_mutation_product.product_id).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).first
  #      @colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
  #      @sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
  #      @colors[stock_mutation_product.product_id].each do |color|
  #        @sizes[stock_mutation_product.product_id].each do |size|
  #          stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.where(size_id: size.id, color_id: color.id).select("1 AS one").blank?
  #        end
  #      end        
  #    end
  #  end
  
  def update
    add_additional_params("store to store")
    if @valid
      @stock_mutation.quantity = @total_stock_mutation_quantity
      @stock_mutation.mutation_type = "store to store"
      unless @saved = @stock_mutation.update(stock_mutation_params)
        if @stock_mutation.errors[:base].present?
          render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:base].join("<br/>")}\",size: 'small'});"
        elsif @stock_mutation.errors[:"stock_mutation_products.base"].present?
          render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.base"].join("<br/>")}\",size: 'small'});"
        elsif @stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].present?
          render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].join("<br/>")}\",size: 'small'});"
        else        
          #          @destintation_warehouses = Warehouse.not_central.where(["id <> ?", @stock_mutation.origin_warehouse_id]).select(:id, :code)
          #          @colors = []
          #          @sizes = []
          #          @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
          #            stock_product = StockProduct.joins(:stock).where(product_id: stock_mutation_product.product_id).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).first
          #            @colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
          #            @sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
          #            @colors[stock_mutation_product.product_id].each do |color|
          #              @sizes[stock_mutation_product.product_id].each do |size|
          #                stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.where(size_id: size.id, color_id: color.id).select("1 AS one").blank?
          #              end
          #            end        
          #          end
          
          
          @origin_warehouses = @destintation_warehouses = Warehouse.not_central.select(:id, :code)
          selected_product_ids = []
          params[:stock_mutation][:stock_mutation_products_attributes].each do |key, value|
            selected_product_ids << params[:stock_mutation][:stock_mutation_products_attributes][key][:product_id]
          end
          @selected_products = Product.joins(stock_products: :stock).
            where(id: selected_product_ids).
            where(["stocks.warehouse_id = ?", @stock_mutation.origin_warehouse_id]).
            select(:id).select("stock_products.id AS stock_product_id")
          stock_products = if @selected_products.length > 1
            StockProduct.joins(:stock).includes(:colors, :sizes).where(product_id: @selected_products.pluck(:id)).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).select(:id, :product_id)
          else
            StockProduct.joins(:stock).where(product_id: @selected_products.pluck(:id)).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).select(:id, :product_id)
          end
          @stock_mutation_products = []
          @product_colors = {}
          @product_sizes = {}
          @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
            unless @stock_mutation.origin_warehouse_id_changed?
              stock_product = stock_products.select{|sp| sp.product_id == stock_mutation_product.product_id}.first
              if stock_products.length > 1
                @product_colors[stock_mutation_product.product_id] = stock_product.colors.distinct
                @product_sizes[stock_mutation_product.product_id] = stock_product.sizes.distinct
              else
                @product_colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
                @product_sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
              end
              @product_colors[stock_mutation_product.product_id].each do |color|
                @product_sizes[stock_mutation_product.product_id].each do |size|
                  stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.select{|smpi| smpi.color_id == color.id && smpi.size_id == size.id}.blank?
                end
              end        
              @stock_mutation_products << stock_mutation_product
            else
              if stock_mutation_product.new_record?
                stock_product = stock_products.select{|sp| sp.product_id == stock_mutation_product.product_id}.first    
                if stock_products.length > 1
                  @product_colors[stock_mutation_product.product_id] = stock_product.colors.distinct
                  @product_sizes[stock_mutation_product.product_id] = stock_product.sizes.distinct
                else
                  @product_colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
                  @product_sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
                end
                @product_colors[stock_mutation_product.product_id].each do |color|
                  @product_sizes[stock_mutation_product.product_id].each do |size|
                    stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.select{|smpi| smpi.color_id == color.id && smpi.size_id == size.id}.blank?
                  end
                end        
                @stock_mutation_products << stock_mutation_product
              end
            end
          end

        end
      end
    else
      render js: "bootbox.alert({message: \"#{@error_message}\",size: 'small'});"
    end
  end
  
  #  def update_store_to_warehouse
  #    add_additional_params_for_edit("store to warehouse")
  #    @stock_mutation.quantity = @total_stock_mutation_quantity
  #    @stock_mutation.mutation_type = "store to warehouse"
  #    unless @saved = @stock_mutation.update(stock_mutation_params)
  #      if @stock_mutation.errors[:base].present?
  #        render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:base].join("<br/>")}\",size: 'small'});"
  #      elsif @stock_mutation.errors[:"stock_mutation_products.base"].present?
  #        render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.base"].join("<br/>")}\",size: 'small'});"
  #      elsif @stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].present?
  #        render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:"stock_mutation_products.stock_mutation_product_items.base"].join("<br/>")}\",size: 'small'});"
  #      else        
  #        @destintation_warehouses = Warehouse.central.where(["id <> ?", @stock_mutation.origin_warehouse_id]).select(:id, :code)
  #        @colors = []
  #        @sizes = []
  #        @stock_mutation.stock_mutation_products.each do |stock_mutation_product|
  #          stock_product = StockProduct.joins(:stock).where(product_id: stock_mutation_product.product_id).where(["warehouse_id = ?", @stock_mutation.origin_warehouse_id]).first
  #          @colors[stock_mutation_product.product_id] = stock_product.colors.select(:id, :code, :name)
  #          @sizes[stock_mutation_product.product_id] = stock_product.sizes.select(:id, :size)
  #          @colors[stock_mutation_product.product_id].each do |color|
  #            @sizes[stock_mutation_product.product_id].each do |size|
  #              stock_mutation_product.stock_mutation_product_items.build size_id: size.id, color_id: color.id if stock_mutation_product.stock_mutation_product_items.where(size_id: size.id, color_id: color.id).select("1 AS one").blank?
  #            end
  #          end        
  #        end
  #      end
  #    end
  #  end
  
  def destroy
    unless @stock_mutation.destroy
      @deleted = false
    else
      @deleted = true
    end
  end

  def delete_store_to_warehouse
    unless @stock_mutation.destroy
      @deleted = false
    else
      @deleted = true
    end
  end
  
  def approve
    if current_user.has_non_spg_role? || current_user.sales_promotion_girl.warehouse_id == @stock_mutation.origin_warehouse_id
      begin      
        @valid = @stock_mutation.update(approved_date: Date.current, approving_mutation: true)
      rescue RuntimeError => e
        @runtime_error = e.message
      end
    end
  end
  
  def receive
    @stock_mutation = if current_user.has_non_spg_role?
      StockMutation.joins(:destination_warehouse).
        select("stock_mutations.*").
        where("warehouse_type <> 'central'").where(id: params[:id]).first
    else
      StockMutation.joins(:destination_warehouse).
        select("stock_mutations.*").
        where("warehouse_type <> 'central' AND destination_warehouse_id = #{current_user.sales_promotion_girl.warehouse_id}").
        where(id: params[:id]).first
    end
    @stock_mutation.with_lock do
      @stock_mutation.update(received_date: params[:receive_date], receiving_inventory_to_store: true)      
    end
    if @stock_mutation.errors[:base].present?
      render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:base].join("<br/>")}\",size: 'small'});"
    elsif @stock_mutation.errors[:received_date].present?
      render js: "bootbox.alert({message: \"Receive date #{@stock_mutation.errors[:received_date].join}\",size: 'small'});"
    end
  end

  def receive_to_warehouse
    @stock_mutation = StockMutation.joins(:destination_warehouse).
      select("stock_mutations.*").
      where("warehouse_type = 'central'").where(id: params[:id]).first
    @stock_mutation.with_lock do
      @stock_mutation.update(received_date: params[:receive_date], receiving_inventory_to_warehouse: true)
    end
    if @stock_mutation.errors[:base].present?
      render js: "bootbox.alert({message: \"#{@stock_mutation.errors[:base].join("<br/>")}\",size: 'small'});"
    elsif @stock_mutation.errors[:received_date].present?
      render js: "bootbox.alert({message: \"Receive date #{@stock_mutation.errors[:received_date].join}\",size: 'small'});"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_stock_mutation
    @stock_mutation = if current_user.has_non_spg_role?
      StockMutation.find(params[:id])
    else
      StockMutation.select("stock_mutations.*").
        where(id: params[:id], origin_warehouse_id: current_user.sales_promotion_girl.warehouse_id).first
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def stock_mutation_params
    params.require(:stock_mutation).permit(:delivery_date, :received_date, :quantity, :courier_id, :origin_warehouse_id, :number, :destination_warehouse_id,
      stock_mutation_products_attributes: [:product_code, :product_name, :_destroy, :id, :quantity, :origin_warehouse_id, :product_id,
        stock_mutation_product_items_attributes: [:id, :color_id, :size_id, :quantity,
          :origin_warehouse_id, :product_id, :mutation_type, :_destroy]])
  end
  
  def add_additional_params(type)
    @total_stock_mutation_quantity = 0
    @valid = true
    @error_message = ""
    if params[:stock_mutation][:stock_mutation_products_attributes].present?
      delete_all_products = true
      params[:stock_mutation][:stock_mutation_products_attributes].each do |key, value|
        if params[:stock_mutation][:stock_mutation_products_attributes][key][:_destroy].eql?("0")
          delete_all_products = false
          total_stock_mutation_product_quantity = 0
          params[:stock_mutation][:stock_mutation_products_attributes][key].merge! origin_warehouse_id: params[:stock_mutation][:origin_warehouse_id]
          if params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes].present?
            quantity_present = false
            params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes].each do |smpi_key, smpi_value|
              if params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key][:quantity].present?
                quantity_present = true
                @total_stock_mutation_quantity += params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key][:quantity].to_i
                total_stock_mutation_product_quantity += params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key][:quantity].to_i
                params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key].merge! origin_warehouse_id: params[:stock_mutation][:origin_warehouse_id], product_id: params[:stock_mutation][:stock_mutation_products_attributes][key][:product_id]
                params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key].merge! mutation_type: type
              else
                params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key][:_destroy] = "true"
              end
            end
          
            unless quantity_present
              @error_message = "Please insert at least one piece per product"
              @valid = false
              break
            end
          else
            @error_message = "Please insert at least one piece per product"
            @valid = false
          end
          params[:stock_mutation][:stock_mutation_products_attributes][key][:quantity] = total_stock_mutation_product_quantity
        end
      end
      
      if delete_all_products        
        @error_message = "Sorry, you can't delete all products"
        @valid = false
      end
    else
      @error_message = "Please add at least one product"
      @valid = false
    end
  end
  
  def add_additional_params_for_edit(type)
    @total_stock_mutation_quantity = 0
    @valid = true
    @error_message = ""
    if params[:stock_mutation][:stock_mutation_products_attributes].present?
      delete_all_products = true
      params[:stock_mutation][:stock_mutation_products_attributes].each do |key, value|
        if params[:stock_mutation][:stock_mutation_products_attributes][key][:_destroy].eql?("0")
          delete_all_products = false
          total_stock_mutation_product_quantity = 0
          if params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes].present?
            quantity_present = false
            params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes].each do |smpi_key, smpi_value|
              if params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key][:quantity].present?
                quantity_present = true
                @total_stock_mutation_quantity += params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key][:quantity].to_i
                total_stock_mutation_product_quantity += params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key][:quantity].to_i
                params[:stock_mutation][:stock_mutation_products_attributes][key][:stock_mutation_product_items_attributes][smpi_key].merge! mutation_type: type
              end
            end
            unless quantity_present
              @error_message = "Please insert at least one piece per product"
              @valid = false
              break
            end
          else
            @error_message = "Please insert at least one piece per product"
            @valid = false
          end
          params[:stock_mutation][:stock_mutation_products_attributes][key][:quantity] = total_stock_mutation_product_quantity
        end
      end
      
      if delete_all_products        
        @error_message = "Sorry, you can't delete all products"
        @valid = false
      end

    else
      @error_message = "Please add at least one product"
      @valid = false
    end
  end

end
