include SmartListing::Helper::ControllerExtensions
class ReceivingController < ApplicationController
  load_and_authorize_resource class: ReceivedPurchaseOrder, except: [:get_purchase_order, :receive_products_from_purchase_order]
    helper SmartListing::Helper
    before_action :set_purchase_order, only: [:get_purchase_order, :receive_products_from_purchase_order]
    before_action :set_received_order, only: :show
  
    def index
      like_command = if Rails.env.eql?("production")
        "ILIKE"
      else
        "LIKE"
      end
      if params[:filter_receiving_date].present?
        splitted_date_range = params[:filter_receiving_date].split("-")
        start_date = splitted_date_range[0].strip.to_date
        end_date = splitted_date_range[1].strip.to_date
      end
      received_orders_scope = ReceivedPurchaseOrder.
        joins("LEFT JOIN purchase_orders on received_purchase_orders.purchase_order_id = purchase_orders.id").
        joins(:vendor).
        select(:id, :number, :delivery_order_number, :name, :receiving_date, :quantity, :status)
      received_orders_scope = received_orders_scope.where(["delivery_order_number #{like_command} ?", "%"+params[:filter_string]+"%"]).
        or(received_orders_scope.where(["name #{like_command} ?", "%"+params[:filter_string]+"%"])).
        or(received_orders_scope.where(["number #{like_command} ?", "%"+params[:filter_string]+"%"])).
        or(received_orders_scope.where(["status #{like_command} ?", "%"+params[:filter_string]+"%"])).
        or(received_orders_scope.where(["quantity #{like_command} ?", "%"+params[:filter_string]+"%"])) if params[:filter_string].present?
      received_orders_scope = received_orders_scope.where(["DATE(receiving_date) BETWEEN ? AND ?", start_date, end_date]) if params[:filter_receiving_date].present?
      @received_orders = smart_listing_create(:receiving_purchase_orders, received_orders_scope, partial: 'receiving/listing', default_sort: {receiving_date: "asc"})
    end
  
    def show
    
    end
  
    def new
      @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).
        select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name").
        where("status = 'Open' OR status = 'Partial'")
      @suppliers = Vendor.select(:id, :name)
      @warehouses = Warehouse.central.select :id, :code
      @direct_purchase = DirectPurchase.new
      @direct_purchase.build_received_purchase_order is_using_delivery_order: true
    end
  
    def get_purchase_order    
      @purchase_order.receiving_po = true
      received_purchase_order = @purchase_order.received_purchase_orders.build vendor_id: @purchase_order.vendor_id
      authorize! :manage, received_purchase_order
      @purchase_order.purchase_order_products.joins(:product).select("purchase_order_products.id, code").each do |po_product|
        received_purchase_order_product = received_purchase_order.received_purchase_order_products.build purchase_order_product_id: po_product.id
        po_product.purchase_order_details.select(:id).each do |purchase_order_detail|
          received_purchase_order_product.received_purchase_order_items.build purchase_order_detail_id: purchase_order_detail.id
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
          @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name").where("status = 'Open' OR status = 'Partial'")
          received_purchase_order = @purchase_order.received_purchase_orders.select{|rpo| rpo.new_record?}.first
          @purchase_order.purchase_order_products.joins(:product).select("purchase_order_products.id, code").each do |po_product|
            received_purchase_order_product = received_purchase_order.received_purchase_order_products.select{|rpop| rpop.purchase_order_product_id.eql?(po_product.id)}.first
            received_purchase_order_product = received_purchase_order.received_purchase_order_products.build purchase_order_product_id: po_product.id if received_purchase_order_product.blank?
            po_product.purchase_order_details.select(:id).each do |purchase_order_detail|
              if received_purchase_order_product.received_purchase_order_items.select{|rpoi| rpoi.purchase_order_detail_id.eql?(purchase_order_detail.id)}.blank?
                received_purchase_order_product.received_purchase_order_items.build purchase_order_detail_id: purchase_order_detail.id
              end
            end
          end
        
          render js: "bootbox.alert({message: \"#{@purchase_order.errors[:base].join("<br/>")}\",size: 'small'});" if @purchase_order.errors[:base].present?
          render js: "bootbox.alert({message: \"#{@purchase_order.errors[:"received_purchase_orders.base"].join("<br/>")}\",size: 'small'});" if @purchase_order.errors[:"received_purchase_orders.base"].present? && @purchase_order.errors[:base].blank?
        else        
          @valid = true
          @received_order = ReceivedPurchaseOrder.
            joins(:purchase_order, :vendor).
            select(:id, :number, :delivery_order_number, :name, :receiving_date, :quantity, :status).
            where("purchase_order_id = '#{@purchase_order.id}'").last
        end
      rescue ActiveRecord::RecordNotUnique => e
        @do_number_not_unique = true
        @purchase_orders = PurchaseOrder.joins(:warehouse, :vendor).select("purchase_orders.id, number, status, vendors.name as vendors_name, warehouses.name as warehouses_name").where("status = 'Open' OR status = 'Partial'")
        received_purchase_order = @purchase_order.received_purchase_orders.select{|rpo| rpo.new_record?}.first
        @purchase_order.purchase_order_products.joins(:product).select("purchase_order_products.id, code").each do |po_product|
          received_purchase_order_product = received_purchase_order.received_purchase_order_products.select{|rpop| rpop.purchase_order_product_id.eql?(po_product.id)}.first
          received_purchase_order_product = received_purchase_order.received_purchase_order_products.build purchase_order_product_id: po_product.id if received_purchase_order_product.blank?
          po_product.purchase_order_details.select(:id).each do |purchase_order_detail|
            if received_purchase_order_product.received_purchase_order_items.select{|rpoi| rpoi.purchase_order_detail_id.eql?(purchase_order_detail.id)}.blank?
              received_purchase_order_product.received_purchase_order_items.build purchase_order_detail_id: purchase_order_detail.id
            end
          end
        end
        received_purchase_order.errors.messages[:delivery_order_number] = ["has already been taken"]
      rescue RuntimeError => e
        render js: "bootbox.alert({message: \"#{e.message}\",size: 'small'});"
      end
    end
  
    def get_product_details
      @product_costs = Hash.new
      previous_selected_product_ids = params[:previous_selected_product_ids]
      selected_product_ids = params[:product_ids]
      splitted_selected_product_ids = selected_product_ids.split(",") - previous_selected_product_ids.split(",")
      @direct_purchase = DirectPurchase.new
      if splitted_selected_product_ids.present?
        #      @colors = Color.select(:id, :code).order :code
        @products = Product.where("id IN (#{splitted_selected_product_ids.join(",")})").select(:id, :code)
        @products.each do |product|
          active_cost = product.active_cost_by_po_date(params[:dp_date].to_date).cost rescue 0
          @product_costs[product.id] = active_cost
          existing_dpp = @direct_purchase.direct_purchase_products.select{|dpp| dpp.product_id.eql?(product.id)}.first
          dpp = if existing_dpp.nil?
            @direct_purchase.direct_purchase_products.build product_id: product.id, dp_cost: active_cost
          else
            existing_dpp        
          end
          #        pop = @purchase_order.purchase_order_products.build product_id: product.id
          product.grouped_product_details.each do |gpd|
            product.colors.each do |color|
              existing_item = dpp.direct_purchase_details.select{|dpd| dpd.size_id.eql?(gpd.size.id) and dpd.color_id.eql?(color.id)}.first
              dpp.direct_purchase_details.build size_id: gpd.size.id, color_id: color.id unless existing_item
            end
          end
        end

        # id yang diganti, caranya yang lama dihapus dan yang baru ditambahkan      
        @replaced_ids = previous_selected_product_ids.split(",") - selected_product_ids.split(",")
        respond_to { |format| format.js }
      else
        previous_selected_product_ids = params[:previous_selected_product_ids]
        selected_product_ids = params[:product_ids]
        if previous_selected_product_ids.split(",").length > selected_product_ids.split(",").length
          @removed_ids = previous_selected_product_ids.split(",") - selected_product_ids.split(",")
          products = Product.where(id: selected_product_ids.split(",")).select(:id)
          products.each do |product|
            active_cost = product.active_cost_by_po_date(params[:dp_date].to_date).cost rescue 0
            @product_costs[product.id] = active_cost
          end
          respond_to { |format| format.js }
        else
          products = Product.where(id: selected_product_ids.split(",")).select(:id)
          products.each do |product|
            active_cost = product.active_cost_by_po_date(params[:dp_date].to_date).cost rescue 0
            @product_costs[product.id] = active_cost
          end
          respond_to do |format|
            format.js { render 'update_cost' }
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
          @suppliers = Vendor.select(:id, :name)
          @warehouses = Warehouse.central.select :id, :code
          #        @colors = Color.select(:id, :code).order :code
          @products = Product.where("id IN (#{params[:product_ids]})").select(:id, :code)

          @direct_purchase.direct_purchase_products.each do |dpp|
            dpp.product.grouped_product_details.each do |gpd|
              dpp.product.colors.each do |color|
                dpp.direct_purchase_details.build size_id: gpd.size.id, color_id: color.id if dpp.direct_purchase_details.select{|dpd| dpd.size_id.eql?(gpd.size.id) and dpd.color_id.eql?(color.id)}.blank?
              end
            end
          end
          
          if @direct_purchase.errors[:base].present?
            render js: "bootbox.alert({message: \"#{@direct_purchase.errors[:base].join("\\n")}\",size: 'small'});"
          elsif @direct_purchase.errors[:"direct_purchase_products.base"].present?
            error_message = "Please insert at least one piece per product!"
            render js: "bootbox.alert({message: \"#{error_message}\",size: 'small'});" if @direct_purchase.errors[:"direct_purchase_products.base"].to_sentence.eql?(error_message)
          end
        else
          @product_received = true
          @received_order = ReceivedPurchaseOrder.
            joins(:direct_purchase, :vendor).
            select(:id, :delivery_order_number, :name, :receiving_date, :quantity).
            where("direct_purchase_id = '#{@direct_purchase.id}'").last
        end
      rescue ActiveRecord::RecordNotUnique => e
        @suppliers = Vendor.select(:id, :name)
        @warehouses = Warehouse.central.select :id, :code
        #      @colors = Color.select(:id, :code).order :code
        @products = Product.where("id IN (#{params[:product_ids]})").select(:id, :code)

        @direct_purchase.direct_purchase_products.each do |dpp|
          dpp.product.grouped_product_details.each do |gpd|
            dpp.product.colors.each do |color|
              dpp.direct_purchase_details.build size_id: gpd.size.id, color_id: color.id if dpp.direct_purchase_details.select{|dpd| dpd.size_id.eql?(gpd.size.id) and dpd.color_id.eql?(color.id)}.blank?
            end
          end
        end
        @direct_purchase.received_purchase_order.errors.messages[:delivery_order_number] = ["has already been taken"]
      end
    end
  
    private
  
    def purchase_order_params
      params.require(:purchase_order).permit(:id, received_purchase_orders_attributes: [:vendor_id, :receiving_date, :is_using_delivery_order, :delivery_order_number, 
          received_purchase_order_products_attributes: [:purchase_order_id, :purchase_order_product_id,
            received_purchase_order_items_attributes: [:purchase_order_detail_id, :quantity, :purchase_order_product_id, :purchase_order_id, :receiving_date, :warehouse_id, :product_id]]]).merge(receiving_po: true)
    end
  
    def direct_purchase_params
      params.require(:direct_purchase).permit(:receiving_date, :vendor_id, :warehouse_id, :first_discount, :second_discount, :is_additional_disc_from_net,
        received_purchase_order_attributes: [:is_using_delivery_order, :delivery_order_number], 
        direct_purchase_products_attributes: [:dp_cost, :product_id, :receiving_date,
          direct_purchase_details_attributes: [:size_id, :color_id, :quantity, :product_id]])
    end
  
    def set_purchase_order
      @purchase_order = PurchaseOrder.where(id: params[:id]).select("purchase_orders.id, number, name, purchase_order_date, status, first_discount, second_discount, vendor_id, warehouse_id").joins(:vendor).first
    end
  
    def set_received_order
      @received_order = ReceivedPurchaseOrder.where(id: params[:id]).select(:id, :delivery_order_number, :purchase_order_id, :direct_purchase_id, :receiving_date, :vendor_id, :quantity).first
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
      params[:direct_purchase][:direct_purchase_products_attributes].each do |key, value|
        params[:direct_purchase][:direct_purchase_products_attributes][key].merge! receiving_date: params[:direct_purchase][:receiving_date]
        product_id = params[:direct_purchase][:direct_purchase_products_attributes][key][:product_id]
        params[:direct_purchase][:direct_purchase_products_attributes][key][:direct_purchase_details_attributes].each do |dpd_key, value|
          params[:direct_purchase][:direct_purchase_products_attributes][key][:direct_purchase_details_attributes][dpd_key].merge! product_id: product_id
        end if params[:direct_purchase][:direct_purchase_products_attributes][key][:direct_purchase_details_attributes].present?
      end if params[:direct_purchase][:direct_purchase_products_attributes].present?
    end
  
  end
