include SmartListing::Helper::ControllerExtensions
class AdjustmentsController < ApplicationController
  authorize_resource
  helper SmartListing::Helper
  
  # GET /adjustments
  # GET /adjustments.json
  def index
    if params[:filter_date].present?
      splitted_start_time_range = params[:filter_date].split("-")
      start_date = splitted_start_time_range[0].strip.to_date
      end_date = splitted_start_time_range[1].strip.to_date
    end

    adjustments_scope = Adjustment.select(:id, :number, :adj_type, :adj_date, :quantity, "warehouses.code", "warehouses.name").joins(:warehouse)
    adjustments_scope = adjustments_scope.where(["number ILIKE ?", "%"+params[:filter_number]+"%"]) if params[:filter_number].present?
    adjustments_scope = adjustments_scope.where(["warehouse_id = ?", params[:filter_warehouse]]) if params[:filter_warehouse].present?
    adjustments_scope = adjustments_scope.where(["adj_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_date].present?
    adjustments_scope = adjustments_scope.where(["adj_type = ?", params[:filter_type]]) if params[:filter_type].present?
    smart_listing_create(:adjustments, adjustments_scope, partial: 'adjustments/listing', default_sort: {number: "asc"})
  end

  # GET /adjustments/1
  # GET /adjustments/1.json
  def show
    @adjustment = Adjustment.select(:id, "warehouses.code AS warehouse_code", "warehouses.name AS warehouse_name", :adj_type, :adj_date, :quantity, :number).joins(:warehouse).find(params[:id])
  end

  # GET /adjustments/new
  def new
    @warehouses = Warehouse.select(:id, :code, :name).not_in_transit.not_direct_sales.actived.order(:code)
    @adjustment = Adjustment.new
  end

  # POST /adjustments
  # POST /adjustments.json
  def create
    add_additional_params_to_child
    @adjustment = Adjustment.new(adjustment_params)

    recreate = false
    recreate_counter = 1

    begin
      begin
        recreate = false
        unless @valid = @adjustment.save
          if @adjustment.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@adjustment.errors[:base].join("<br/>")}\",size: 'small'});"
          elsif @adjustment.errors[:"adjustment_products.base"].present?
            render js: "bootbox.alert({message: \"#{@adjustment.errors[:"adjustment_products.base"].join("<br/>")}\",size: 'small'});"
          else
            @warehouses = Warehouse.select(:id, :code, :name).not_in_transit.not_direct_sales.actived.order(:code)
            @adjustment_products = []
            @adjustment.adjustment_products.each do |ap|
              product_colors = ProductColor.select("common_fields.id", "common_fields.code AS color_code", "common_fields.name AS color_name").joins(:color).where(product_id: ap.product_id).order("common_fields.code")
              product_sizes = ProductDetail.select("sizes.id", "sizes.size AS product_size").joins(:size).where(product_id: ap.product_id).order("sizes.size_order")
              product_colors.each do |product_color|
                product_sizes.each do |product_size|
                  adjustment_product_detail = ap.adjustment_product_details.select{|apd| apd.size_id == product_size.id && apd.color_id == product_color.id}.first
                  if adjustment_product_detail.present?
                    ap.adjustment_product_details.delete(adjustment_product_detail)
                    ap.adjustment_product_details << adjustment_product_detail
                  else
                    ap.adjustment_product_details.build size_id: product_size.id, color_id: product_color.id, quantity: nil, attr_color_code: product_color.color_code, attr_color_name: product_color.color_name, attr_size: product_size.product_size
                  end
                end
              end
              @adjustment_products << ap
            end
          end
        else
          @warehouse = Warehouse.select(:code, :name).find(@adjustment.warehouse_id)
        end
      rescue ActiveRecord::RecordNotUnique => e
        if recreate_counter < 5
          recreate = true
          recreate_counter += 1
        else
          recreate = false
          render js: "bootbox.alert({message: \"Something went wrong. Please try again\",size: 'small'});"
        end
      end
    end while recreate
  end

  def autocomplete_product_code 
    products = Product.select(:id, :code, "common_fields.name AS brand_name").joins(:brand).where("LOWER(products.code) LIKE LOWER('#{params[:term]}%')").order(:code)
    render json: products.map { |product|
      {
        id:    product.id,
        label: product.code_and_brand
      }
    }
  end
  
  def get_product
    products = Product.select(:id, :code, "common_fields.name AS brand_name").joins(:brand).where(code: params[:product_codes])
    if products.present?
      @adjustment_products = []
      adjustment = Adjustment.new
      products.each do |product|        
        adjustment_product = adjustment.adjustment_products.build(product_id: product.id, attr_product_code: product.code, attr_brand_name: product.brand_name)
        product_colors = ProductColor.select("common_fields.id", "common_fields.code AS color_code", "common_fields.name AS color_name").joins(:color).where(product_id: product.id).order("common_fields.code")
        product_sizes = ProductDetail.select("sizes.id", "sizes.size AS product_size").joins(:size).where(product_id: product.id).order("sizes.size_order")
        product_colors.each do |product_color|
          product_sizes.each do |product_size|
            adjustment_product.adjustment_product_details.build size_id: product_size.id, color_id: product_color.id, quantity: nil, attr_color_code: product_color.color_code, attr_color_name: product_color.color_name, attr_size: product_size.product_size
          end
        end
        @adjustment_products << adjustment_product
      end
    else
      render js: "bootbox.alert({message: \"No records found\",size: 'small'});"
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_adjustment
    @adjustment = Adjustment.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def adjustment_params
    params.require(:adjustment).permit(:warehouse_id, :adj_type, :adj_date, :quantity, adjustment_products_attributes: [:product_id, :attr_product_code, :attr_brand_name, :attr_warehouse_id, :quantity,
        adjustment_product_details_attributes: [:size_id, :color_id, :attr_color_code, :attr_color_name, :attr_size, :quantity, :attr_warehouse_id, :attr_adj_date, :attr_product_id]])
  end
  
  def add_additional_params_to_child
    quantity = 0
    params[:adjustment][:adjustment_products_attributes].each do |key, value|
      quantity_per_product = 0
      params[:adjustment][:adjustment_products_attributes][key][:adjustment_product_details_attributes].each do |apd_key, value|
        quantity_per_product += params[:adjustment][:adjustment_products_attributes][key][:adjustment_product_details_attributes][apd_key][:quantity].to_i
        params[:adjustment][:adjustment_products_attributes][key][:adjustment_product_details_attributes][apd_key].merge! attr_warehouse_id: params[:adjustment][:warehouse_id], attr_adj_date: params[:adjustment][:adj_date], attr_product_id: params[:adjustment][:adjustment_products_attributes][key][:product_id]
      end if params[:adjustment][:adjustment_products_attributes][key][:adjustment_product_details_attributes].present?
      params[:adjustment][:adjustment_products_attributes][key].merge! attr_warehouse_id: params[:adjustment][:warehouse_id], quantity: quantity_per_product
      quantity += quantity_per_product
    end if params[:adjustment][:adjustment_products_attributes].present?
    params[:adjustment].merge! quantity: quantity
  end
end
