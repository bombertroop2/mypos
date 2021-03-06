include SmartListing::Helper::ControllerExtensions
class ReceivingController < ApplicationController
  autocomplete :product, :code, :extra_data => [:brand_id], display_value: :autocomplete_display_value
  authorize_resource class: ReceivedPurchaseOrder, except: [:get_purchase_order, :receive_products_from_purchase_order]
    helper SmartListing::Helper
    before_action :set_purchase_order, only: [:get_purchase_order, :receive_products_from_purchase_order]
    before_action :set_received_order, only: :show

    def index
      like_command = "ILIKE"
      if params[:filter_receiving_date].present?
        splitted_date_range = params[:filter_receiving_date].split("-")
        start_date = splitted_date_range[0].strip.to_date
        end_date = splitted_date_range[1].strip.to_date
      end
      received_orders_scope = ReceivedPurchaseOrder.
        joins("LEFT JOIN purchase_orders on received_purchase_orders.purchase_order_id = purchase_orders.id").
        joins(:vendor).
        select(:id, :number, :transaction_number, :delivery_order_number, :name, :receiving_date, :quantity, :status)
      received_orders_scope = received_orders_scope.where(["delivery_order_number #{like_command} ?", "%"+params[:filter_string]+"%"]).
        or(received_orders_scope.where(["transaction_number #{like_command} ?", "%"+params[:filter_string]+"%"])).
        or(received_orders_scope.where(["name #{like_command} ?", "%"+params[:filter_string]+"%"])).
        or(received_orders_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"])).
        or(received_orders_scope.where(["status #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
      received_orders_scope = received_orders_scope.where(["DATE(receiving_date) BETWEEN ? AND ?", start_date, end_date]) if params[:filter_receiving_date].present?
      @received_orders = smart_listing_create(:receiving_purchase_orders, received_orders_scope, partial: 'receiving/listing', default_sort: {receiving_date: "asc"})
    end

    def show

    end

    def new
      @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).
        select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name").
        where("status = 'Open' OR status = 'Partial'").where(["vendors.is_active = ?", true])
      @suppliers = Vendor.select(:id, :name).where(is_active: true)
      @warehouses = Warehouse.central.select :id, :code
      @direct_purchase = DirectPurchase.new
      @direct_purchase.build_received_purchase_order is_using_delivery_order: true
    end

    def get_purchase_order
      @purchase_order.receiving_po = true
      received_purchase_order = @purchase_order.received_purchase_orders.build vendor_id: @purchase_order.vendor_id
      authorize! :manage, received_purchase_order
      @colors = []
      @sizes = []
      @purchase_order.purchase_order_products.joins([product: :brand], :cost_list).includes(:size_selected_columns, :color_selected_columns).select("purchase_order_products.id, products.code AS product_code, common_fields.name AS product_name, cost").each do |po_product|
        @colors[po_product.id] = po_product.color_selected_columns.distinct
        @sizes[po_product.id] = po_product.size_selected_columns.distinct
        received_purchase_order_product = received_purchase_order.received_purchase_order_products.build purchase_order_product_id: po_product.id, prdct_code: po_product.product_code, prdct_name: po_product.product_name, prdct_cost: po_product.cost
        po_product.purchase_order_details_selected_columns.each do |purchase_order_detail|
          received_purchase_order_product.received_purchase_order_items.build purchase_order_detail_id: purchase_order_detail.id, pod: purchase_order_detail
        end
      end
    end

    def receive_products_from_purchase_order
      add_additional_params_to_child
      authorize! :manage, ReceivedPurchaseOrder
      begin
        @do_number_not_unique = false
        @valid = false
        unless @purchase_order.update(purchase_order_params)
          #          @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name").where("status = 'Open' OR status = 'Partial'")
          received_purchase_order = @purchase_order.received_purchase_orders.select{|rpo| rpo.new_record?}.first
          @colors = []
          @sizes = []
          @purchase_order.purchase_order_products.joins([product: :brand], :cost_list).includes(:size_selected_columns, :color_selected_columns, :purchase_order_details_selected_columns).select("purchase_order_products.id, products.code AS product_code, common_fields.name AS product_name, cost").each do |po_product|
            @colors[po_product.id] = po_product.color_selected_columns.distinct
            @sizes[po_product.id] = po_product.size_selected_columns.distinct
            received_purchase_order_product = received_purchase_order.received_purchase_order_products.select{|rpop| rpop.purchase_order_product_id.eql?(po_product.id)}.first
            if received_purchase_order_product.blank?
              received_purchase_order_product = received_purchase_order.received_purchase_order_products.build purchase_order_product_id: po_product.id, prdct_code: po_product.product_code, prdct_name: po_product.product_name, prdct_cost: po_product.cost
            else
              received_purchase_order_product.prdct_code = po_product.product_code
              received_purchase_order_product.prdct_name = po_product.product_name
              received_purchase_order_product.prdct_cost = po_product.cost
            end
            po_product.purchase_order_details_selected_columns.each do |purchase_order_detail|
              if (rpoi = received_purchase_order_product.received_purchase_order_items.select{|rpoi| rpoi.purchase_order_detail_id.eql?(purchase_order_detail.id)}.first).blank?
                received_purchase_order_product.received_purchase_order_items.build purchase_order_detail_id: purchase_order_detail.id, pod: purchase_order_detail
              else
                rpoi.pod = purchase_order_detail
              end
            end
          end

          render js: "bootbox.alert({message: \"#{@purchase_order.errors[:base].join("<br/>")}\",size: 'small'});" if @purchase_order.errors[:base].present?
          render js: "bootbox.alert({message: \"#{@purchase_order.errors[:"received_purchase_orders.base"].join("<br/>")}\",size: 'small'});" if @purchase_order.errors[:"received_purchase_orders.base"].present? && @purchase_order.errors[:base].blank?
          render js: "bootbox.alert({message: \"#{@purchase_order.errors[:"received_purchase_orders.received_purchase_order_products.received_purchase_order_items.base"].join("<br/>")}\",size: 'small'});" if @purchase_order.errors[:"received_purchase_orders.received_purchase_order_products.received_purchase_order_items.base"].present? && @purchase_order.errors[:base].blank? && @purchase_order.errors[:"received_purchase_orders.base"]
        else
          @valid = true
          @received_order = ReceivedPurchaseOrder.
            joins(:purchase_order, :vendor).
            select(:id, :number, :delivery_order_number, :transaction_number, :name, :receiving_date, :quantity, :status).
            where("purchase_order_id = '#{@purchase_order.id}'").last
        end
      rescue ActiveRecord::RecordNotUnique => e
        @do_number_not_unique = true
        #        @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name").where("status = 'Open' OR status = 'Partial'")
        received_purchase_order = @purchase_order.received_purchase_orders.select{|rpo| rpo.new_record?}.first
        @colors = []
        @sizes = []
        @purchase_order.purchase_order_products.joins([product: :brand], :cost_list).includes(:size_selected_columns, :color_selected_columns, :purchase_order_details_selected_columns).select("purchase_order_products.id, products.code AS product_code, common_fields.name AS product_name, cost").each do |po_product|
          @colors[po_product.id] = po_product.color_selected_columns.distinct
          @sizes[po_product.id] = po_product.size_selected_columns.distinct
          received_purchase_order_product = received_purchase_order.received_purchase_order_products.select{|rpop| rpop.purchase_order_product_id.eql?(po_product.id)}.first
          if received_purchase_order_product.blank?
            received_purchase_order_product = received_purchase_order.received_purchase_order_products.build purchase_order_product_id: po_product.id, prdct_code: po_product.product_code, prdct_name: po_product.product_name, prdct_cost: po_product.cost
          else
            received_purchase_order_product.prdct_code = po_product.product_code
            received_purchase_order_product.prdct_name = po_product.product_name
            received_purchase_order_product.prdct_cost = po_product.cost
          end
          po_product.purchase_order_details_selected_columns.each do |purchase_order_detail|
            if (rpoi = received_purchase_order_product.received_purchase_order_items.select{|rpoi| rpoi.purchase_order_detail_id.eql?(purchase_order_detail.id)}.first).blank?
              received_purchase_order_product.received_purchase_order_items.build purchase_order_detail_id: purchase_order_detail.id, pod: purchase_order_detail
            else
              rpoi.pod = purchase_order_detail
            end
          end
        end
        received_purchase_order.errors.messages[:delivery_order_number] = ["has already been taken"]
      rescue RuntimeError => e
        render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
      end
    end

    def get_product_details
      @colors = []
      @sizes = []
      @direct_purchase = DirectPurchase.new
      product_ids = params[:product_ids].split(",")
      products = Product.joins(:brand).where(code: product_ids).includes(:colors, :sizes, :cost_list_costs_effective_dates_product_ids).select(:id, :code, :name)
      unavailable_product_codes = product_ids - products.pluck(:code)
      if unavailable_product_codes.length > 0
        render js: "bootbox.alert({message: \"Product #{unavailable_product_codes.first} doesn't exist\",size: 'small'});"
      else
        products.each do |product|
          active_cost = product.active_cost_by_po_date(params[:dp_date].to_date, product.cost_list_costs_effective_dates_product_ids).cost rescue 0
          @colors[product.id] = product.colors.distinct
          @sizes[product.id] = product.sizes.distinct
          dpp = @direct_purchase.direct_purchase_products.build product_id: product.id, dp_cost: active_cost, prdct_code: product.code, prdct_name: product.name
          @colors[product.id].each do |color|
            @sizes[product.id].each do |size|
              dpp.direct_purchase_details.build size_id: size.id, color_id: color.id
            end
          end
        end
      end
    end

    def create
      add_additional_params_to_direct_purchase_products
      @direct_purchase = DirectPurchase.new(direct_purchase_params)
      @direct_purchase.received_purchase_order.is_it_direct_purchasing = true
      @direct_purchase.received_purchase_order.vendor_id = params[:direct_purchase][:vendor_id]
      begin
        unless @direct_purchase.save
          @colors = []
          @sizes = []
          @suppliers = Vendor.select(:id, :name).where(is_active: true)
          @warehouses = Warehouse.central.select :id, :code
          #        @colors = Color.select(:id, :code).order :code
          products = Product.joins(:brand).where(id: @direct_purchase.direct_purchase_products.map(&:product_id)).includes(:colors, :sizes, :cost_list_costs_effective_dates_product_ids).select(:id, :code, :name)
          @direct_purchase.direct_purchase_products.each do |dpp|
            product = products.select{|prdct| prdct.id == dpp.product_id}.first
            dpp.prdct_code = product.code
            dpp.prdct_name = product.name
            @colors[product.id] = product.colors.distinct
            @sizes[product.id] = product.sizes.distinct
            @colors[product.id].each do |color|
              @sizes[product.id].each do |size|
                dpp.direct_purchase_details.build size_id: size.id, color_id: color.id if dpp.direct_purchase_details.select{|dpd| dpd.size_id.eql?(size.id) and dpd.color_id.eql?(color.id)}.blank?
              end
            end
          end

          if @direct_purchase.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@direct_purchase.errors[:base].join("<br/>")}\",size: 'small'});"
          elsif @direct_purchase.errors[:"direct_purchase_products.base"].present?
            error_message = "Please insert at least one piece per product!"
            render js: "bootbox.alert({message: \"#{error_message}\",size: 'small'});" if @direct_purchase.errors[:"direct_purchase_products.base"].to_sentence.eql?(error_message)
          elsif @direct_purchase.errors[:"direct_purchase_products.direct_purchase_details.base"].present?
            render js: "bootbox.alert({message: \"#{@direct_purchase.errors[:"direct_purchase_products.direct_purchase_details.base"].join("<br/>")}\",size: 'small'});"
          elsif @direct_purchase.received_purchase_order.present? && @direct_purchase.received_purchase_order.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@direct_purchase.received_purchase_order.errors[:base].join("<br/>")}\",size: 'small'});"
          end
        else
          @product_received = true
          @received_order = ReceivedPurchaseOrder.
            joins(:direct_purchase, :vendor).
            select(:id, :delivery_order_number, :transaction_number, :name, :receiving_date, :quantity).
            where("direct_purchase_id = '#{@direct_purchase.id}'").last
        end
      rescue ActiveRecord::RecordNotUnique => e
        @colors = []
        @sizes = []
        @suppliers = Vendor.select(:id, :name).where(is_active: true)
        @warehouses = Warehouse.central.select :id, :code
        #      @colors = Color.select(:id, :code).order :code
        products = Product.joins(:brand).where(id: @direct_purchase.direct_purchase_products.map(&:product_id)).includes(:colors, :sizes, :cost_list_costs_effective_dates_product_ids).select(:id, :code, :name)

        @direct_purchase.direct_purchase_products.each do |dpp|
          product = products.select{|prdct| prdct.id == dpp.product_id}.first
          dpp.prdct_code = product.code
          dpp.prdct_name = product.name
          @colors[product.id] = product.colors.distinct
          @sizes[product.id] = product.sizes.distinct
          @colors[product.id].each do |color|
            @sizes[product.id].each do |size|
              dpp.direct_purchase_details.build size_id: size.id, color_id: color.id if dpp.direct_purchase_details.select{|dpd| dpd.size_id.eql?(size.id) and dpd.color_id.eql?(color.id)}.blank?
            end
          end
        end
        @direct_purchase.received_purchase_order.errors.messages[:delivery_order_number] = ["has already been taken"]
      rescue RuntimeError => e
        @colors = []
        @sizes = []
        @suppliers = Vendor.select(:id, :name).where(is_active: true)
        @warehouses = Warehouse.central.select :id, :code
        products = Product.joins(:brand).where(id: @direct_purchase.direct_purchase_products.map(&:product_id)).includes(:colors, :sizes, :cost_list_costs_effective_dates_product_ids).select(:id, :code, :name)

        @direct_purchase.direct_purchase_products.each do |dpp|
          product = products.select{|prdct| prdct.id == dpp.product_id}.first
          dpp.prdct_code = product.code
          dpp.prdct_name = product.name
          @colors[product.id] = product.colors.distinct
          @sizes[product.id] = product.sizes.distinct
          @colors[product.id].each do |color|
            @sizes[product.id].each do |size|
              dpp.direct_purchase_details.build size_id: size.id, color_id: color.id if dpp.direct_purchase_details.select{|dpd| dpd.size_id.eql?(size.id) and dpd.color_id.eql?(color.id)}.blank?
            end
          end
        end
        @direct_purchase.received_purchase_order.errors.messages[:delivery_order_number] = [e.message]
      end
    end
    
    def search_do_numbers      
      @received_purchase_orders = ReceivedPurchaseOrder.where(["delivery_order_number ILIKE ? AND receiving_date = ?", params[:term]+"%", params[:receiving_date].to_date]).pluck(:delivery_order_number).uniq
      respond_to do |format|
        format.json  { render :json => @received_purchase_orders.to_json }
      end
    end
    
    def goods_received_not_invoiced
      if params[:filter_receiving_date_grni].present?
        splitted_date_range = params[:filter_receiving_date_grni].split("-")
        start_date = splitted_date_range[0].strip.to_date
        end_date = splitted_date_range[1].strip.to_date
      end

      received_orders_scope = ReceivedPurchaseOrder.
        select(:id, :delivery_order_number, :receiving_date, :quantity, :transaction_number, :checked, "purchase_orders.number AS po_number", "vendors.code AS vendor_code", "vendors.name AS vendor_name").
        joins(:vendor).
        joins("LEFT JOIN purchase_orders ON received_purchase_orders.purchase_order_id = purchase_orders.id").
        joins("LEFT JOIN direct_purchases ON received_purchase_orders.direct_purchase_id = direct_purchases.id").
        where("(received_purchase_orders.invoice_status = '' AND purchase_orders.invoice_status = 'Partial') OR purchase_orders.invoice_status = '' OR direct_purchases.invoice_status = ''")
      
      received_orders_scope = received_orders_scope.where(["received_purchase_orders.receiving_date BETWEEN ? AND ?", start_date, end_date]) if params[:filter_receiving_date_grni].present?
      received_orders_scope = received_orders_scope.where(["received_purchase_orders.delivery_order_number ILIKE ? OR received_purchase_orders.transaction_number ILIKE ? OR purchase_orders.number ILIKE ?", "%"+params[:filter_string_grni]+"%", "%"+params[:filter_string_grni]+"%", "%"+params[:filter_string_grni]+"%"]) if params[:filter_string_grni].present?
      received_orders_scope = received_orders_scope.where(["received_purchase_orders.vendor_id = ?", params[:filter_vendor_grni]]) if params[:filter_vendor_grni].present?

      smart_listing_create(:receiving_purchase_orders, received_orders_scope, partial: 'receiving/listing_grni', default_sort: {receiving_date: "asc"})
    end
    
    def check_grni
      @received_purchase_order = ReceivedPurchaseOrder.
        select(:id, :delivery_order_number, :receiving_date, :quantity, :transaction_number, :checked, "purchase_orders.number AS po_number", "vendors.code AS vendor_code", "vendors.name AS vendor_name").
        joins(:vendor).
        joins("LEFT JOIN purchase_orders ON received_purchase_orders.purchase_order_id = purchase_orders.id").
        joins("LEFT JOIN direct_purchases ON received_purchase_orders.direct_purchase_id = direct_purchases.id").
        where("(received_purchase_orders.invoice_status = '' AND purchase_orders.invoice_status = 'Partial') OR purchase_orders.invoice_status = '' OR direct_purchases.invoice_status = ''").
        find(params[:id])
      @received_purchase_order.update(checked: (@received_purchase_order.checked ? false : true), attr_check_grni: true)
    end

    private

    def purchase_order_params
      params.require(:purchase_order).permit(:id, received_purchase_orders_attributes: [:vendor_id, :receiving_date, :is_using_delivery_order, :delivery_order_number,
          received_purchase_order_products_attributes: [:purchase_order_id, :purchase_order_product_id,
            received_purchase_order_items_attributes: [:purchase_order_detail_id, :quantity, :purchase_order_product_id, :purchase_order_id, :receiving_date, :warehouse_id, :product_id]]]).merge(receiving_po: true)
    end

    def direct_purchase_params
      params.require(:direct_purchase).permit(:receiving_date, :vendor_id, :warehouse_id, :first_discount, :second_discount, :is_additional_disc_from_net, :attr_total_qty, :attr_total_gross_amt,
        received_purchase_order_attributes: [:is_using_delivery_order, :delivery_order_number],
        direct_purchase_products_attributes: [:dp_cost, :product_id, :receiving_date, :prdct_code, :cost_list_id,
          direct_purchase_details_attributes: [:size_id, :color_id, :quantity, :product_id, :warehouse_id, :receiving_date, :total_unit_price]])
    end

    def set_purchase_order
      @purchase_order = PurchaseOrder.where(id: params[:id]).where(["vendors.is_active = ?", true]).select("purchase_orders.id, number, name, purchase_order_date, status, first_discount, second_discount, vendor_id, warehouse_id").joins(:vendor).first
    end

    def set_received_order
      @received_order = ReceivedPurchaseOrder.where(id: params[:id]).select(:id, :delivery_order_number, :purchase_order_id, :direct_purchase_id, :receiving_date, :vendor_id, :quantity, :transaction_number).first
    end

    def add_additional_params_to_child
      params[:purchase_order][:received_purchase_orders_attributes].each do |key, value|
        params[:purchase_order][:received_purchase_orders_attributes][key][:received_purchase_order_products_attributes].each do |rpop_key, value|
          params[:purchase_order][:received_purchase_orders_attributes][key][:received_purchase_order_products_attributes][rpop_key].merge! purchase_order_id: @purchase_order.id
          purchase_order_product_id = params[:purchase_order][:received_purchase_orders_attributes][key][:received_purchase_order_products_attributes][rpop_key][:purchase_order_product_id]
          product_id = PurchaseOrderProduct.where(id: purchase_order_product_id).select(:product_id).first.product_id
          params[:purchase_order][:received_purchase_orders_attributes][key][:received_purchase_order_products_attributes][rpop_key][:received_purchase_order_items_attributes].each do |rpoi_key, value|
            params[:purchase_order][:received_purchase_orders_attributes][key][:received_purchase_order_products_attributes][rpop_key][:received_purchase_order_items_attributes][rpoi_key].merge! purchase_order_product_id: params[:purchase_order][:received_purchase_orders_attributes][key][:received_purchase_order_products_attributes][rpop_key][:purchase_order_product_id], purchase_order_id: @purchase_order.id, receiving_date: params[:purchase_order][:received_purchase_orders_attributes][key][:receiving_date], warehouse_id: @purchase_order.warehouse_id, product_id: product_id
          end if params[:purchase_order][:received_purchase_orders_attributes][key][:received_purchase_order_products_attributes][rpop_key][:received_purchase_order_items_attributes].present?
        end if params[:purchase_order][:received_purchase_orders_attributes][key][:received_purchase_order_products_attributes].present?
      end if params[:purchase_order][:received_purchase_orders_attributes].present?
    end

    def add_additional_params_to_direct_purchase_products
      product_codes = params[:receiving_product_ids].split(",")
      product_codes = product_codes.map do |pc|
        parsed_code = Nokogiri::HTML.parse(pc)
        parsed_code.text
      end
      products = Product.joins(:cost_lists).select("products.id, cost_lists.id AS cost_list_id, cost").where(code: product_codes).where(["effective_date <= ?", params[:direct_purchase][:receiving_date].to_date]).order("effective_date DESC")
      params[:direct_purchase][:direct_purchase_products_attributes].each do |key, value|
        product_id = params[:direct_purchase][:direct_purchase_products_attributes][key][:product_id]
        cost_list = products.select{|product| product.id == product_id.to_i}.first
        params[:direct_purchase][:direct_purchase_products_attributes][key].merge! receiving_date: params[:direct_purchase][:receiving_date], cost_list_id: (cost_list.cost_list_id rescue nil)
        params[:direct_purchase][:direct_purchase_products_attributes][key][:direct_purchase_details_attributes].each do |dpd_key, value|
          quantity = params[:direct_purchase][:direct_purchase_products_attributes][key][:direct_purchase_details_attributes][dpd_key][:quantity].to_i
          total_unit_price = quantity * cost_list.cost rescue 0
          params[:direct_purchase][:direct_purchase_products_attributes][key][:direct_purchase_details_attributes][dpd_key].merge! product_id: product_id, warehouse_id: params[:direct_purchase][:warehouse_id], receiving_date: params[:direct_purchase][:receiving_date], total_unit_price: total_unit_price
        end if params[:direct_purchase][:direct_purchase_products_attributes][key][:direct_purchase_details_attributes].present?
      end if params[:direct_purchase][:direct_purchase_products_attributes].present?
    end

  end
