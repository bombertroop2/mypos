class SellThrusController < ApplicationController
  def index    
    respond_to do |format|
      if params[:date].present? && (params[:counter].present? || params[:showroom].present? || params[:type].eql?("central counter") || params[:type].eql?("central showroom"))
        @received_date = params[:date].to_date
        qty_sold_end_date = @received_date + 6.months - 1.day
        @warehouse = if params[:counter].present?
          Warehouse.select(:id, :code, :name).find(params[:counter])
        elsif params[:showroom].present?
          Warehouse.select(:id, :code, :name).find(params[:showroom])
        end
        if params[:counter].present? || params[:showroom].present?
          @shipment_products = ShipmentProductItem.
            select("order_booking_product_items.color_id, colors_order_booking_product_items.code AS color_code, colors_order_booking_product_items.name AS color_name, order_booking_products.product_id, products.code AS product_code, common_fields.name AS product_name, SUM(shipment_product_items.quantity) AS qty_received_per_article_color").
            joins(shipment_product: [order_booking_product: [product: :brand], shipment: :order_booking], order_booking_product_item: :color).
            where(["shipments.received_date = ? AND order_bookings.destination_warehouse_id = ?", @received_date, @warehouse.id]).
            group("order_booking_products.product_id, products.code, common_fields.name, order_booking_product_items.color_id, colors_order_booking_product_items.code, colors_order_booking_product_items.name")
        else
          @received_items = []
          received_purchase_order_items = ReceivedPurchaseOrderItem.
            select("purchase_order_details.color_id, common_fields.code AS color_code, common_fields.name AS color_name, purchase_order_products.product_id AS prdct_id, products.code AS product_code, brands_products.name AS product_name, SUM(received_purchase_order_items.quantity) AS qty_received_per_article_color").
            joins(received_purchase_order_product: :received_purchase_order).
            joins(purchase_order_detail: [:color, purchase_order_product: [purchase_order: :warehouse, product: :brand]]).
            where(["received_purchase_orders.receiving_date = ? AND warehouses.warehouse_type = ?", @received_date, "central"]).
            group("purchase_order_products.product_id, products.code, brands_products.name, purchase_order_details.color_id, common_fields.code, common_fields.name")
          received_direct_purchase_items = ReceivedPurchaseOrderItem.
            select("direct_purchase_details.color_id, common_fields.code AS color_code, common_fields.name AS color_name, direct_purchase_products.product_id AS prdct_id, products.code AS product_code, brands_products.name AS product_name, SUM(received_purchase_order_items.quantity) AS qty_received_per_article_color").
            joins(received_purchase_order_product: :received_purchase_order).
            joins(direct_purchase_detail: [:color, direct_purchase_product: [direct_purchase: :warehouse, product: :brand]]).
            where(["received_purchase_orders.receiving_date = ? AND warehouses.warehouse_type = ?", @received_date, "central"]).
            group("direct_purchase_products.product_id, products.code, brands_products.name, direct_purchase_details.color_id, common_fields.code, common_fields.name")
          received_purchase_order_items.each do |rpoi|
            received_item = @received_items.select{|ri| ri[:product_id] == rpoi.prdct_id && ri[:color_id] == rpoi.color_id}.first
            if received_item.blank?
              @received_items << {product_id: rpoi.prdct_id, product_code: rpoi.product_code, product_name: rpoi.product_name, color_id: rpoi.color_id, color_code: rpoi.color_code, color_name: rpoi.color_name, qty_received_per_article_color: rpoi.qty_received_per_article_color}
            else
              received_item[:qty_received_per_article_color] += rpoi.qty_received_per_article_color
            end
          end          
          received_direct_purchase_items.each do |rdpi|
            received_item = @received_items.select{|ri| ri[:product_id] == rdpi.prdct_id && ri[:color_id] == rdpi.color_id}.first
            if received_item.blank?
              @received_items << {product_id: rdpi.prdct_id, product_code: rdpi.product_code, product_name: rdpi.product_name, color_id: rdpi.color_id, color_code: rdpi.color_code, color_name: rdpi.color_name, qty_received_per_article_color: rdpi.qty_received_per_article_color}
            else
              received_item[:qty_received_per_article_color] += rdpi.qty_received_per_article_color
            end
          end
        end
        month = @received_date.month
        year = @received_date.year
        beginning_date_first = nil
        end_date_first = nil
        beginning_date_second = nil
        end_date_second = nil
        beginning_date_third = nil
        end_date_third = nil
        beginning_date_fourth = nil
        end_date_fourth = nil
        beginning_date_fifth = nil
        end_date_fifth = nil
        beginning_date_sixth = nil
        end_date_sixth = nil
        1..6.times do |index|
          if index == 0
            beginning_date_first = @received_date
            end_date_first = @received_date.end_of_month
          elsif index == 1
            beginning_date_second = "1/#{month}/#{year}".to_date
            end_date_second = beginning_date_second.end_of_month
          elsif index == 2
            beginning_date_third = "1/#{month}/#{year}".to_date
            end_date_third = beginning_date_third.end_of_month
          elsif index == 3
            beginning_date_fourth = "1/#{month}/#{year}".to_date
            end_date_fourth = beginning_date_fourth.end_of_month
          elsif index == 4
            beginning_date_fifth = "1/#{month}/#{year}".to_date
            end_date_fifth = beginning_date_fifth.end_of_month
          elsif index == 5            
            beginning_date_sixth = qty_sold_end_date.beginning_of_month
            end_date_sixth = qty_sold_end_date
          end
          if month == 12
            month = 1
            year += 1
          else
            month += 1
          end
        end
       
        if params[:counter].present?
          @consignment_sale_products = ConsignmentSaleProduct.
            select("product_colors.product_id, product_colors.color_id").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_first}' AND consignment_sales.transaction_date <= '#{end_date_first}' THEN 1 ELSE 0 END) AS qty_sold_first").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_second}' AND consignment_sales.transaction_date <= '#{end_date_second}' THEN 1 ELSE 0 END) AS qty_sold_second").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_third}' AND consignment_sales.transaction_date <= '#{end_date_third}' THEN 1 ELSE 0 END) AS qty_sold_third").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_fourth}' AND consignment_sales.transaction_date <= '#{end_date_fourth}' THEN 1 ELSE 0 END) AS qty_sold_fourth").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_fifth}' AND consignment_sales.transaction_date <= '#{end_date_fifth}' THEN 1 ELSE 0 END) AS qty_sold_fifth").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_sixth}' AND consignment_sales.transaction_date <= '#{end_date_sixth}' THEN 1 ELSE 0 END) AS qty_sold_sixth").
            joins(:consignment_sale).
            joins(product_barcode: :product_color).
            where(:"consignment_sales.warehouse_id" => params[:counter]).
            where(:"product_colors.product_id" => @shipment_products.map(&:product_id).uniq).
            group("product_colors.product_id, product_colors.color_id")
        elsif params[:showroom].present?
          @sale_products = SaleProduct.
            select("product_colors.product_id, product_colors.color_id").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_first.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_first.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_first").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_second.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_second.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_second").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_third.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_third.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_third").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_fourth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_fourth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_fourth").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_fifth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_fifth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_fifth").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_sixth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_sixth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_sixth").
            joins(sale: :cashier_opening).
            joins(product_barcode: :product_color).
            where(:"cashier_openings.warehouse_id" => params[:showroom]).
            where(:"product_colors.product_id" => @shipment_products.map(&:product_id).uniq).
            group("product_colors.product_id, product_colors.color_id")
          
          @sales_return_products = SalesReturnProduct.
            select("product_colors.product_id, product_colors.color_id").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_first.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_first.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_first").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_second.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_second.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_second").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_third.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_third.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_third").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_fourth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_fourth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_fourth").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_fifth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_fifth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_fifth").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_sixth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_sixth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_sixth").
            joins(sale_product: [sale: :cashier_opening, product_barcode: :product_color]).
            where(:"cashier_openings.warehouse_id" => params[:showroom]).
            where(:"product_colors.product_id" => @shipment_products.map(&:product_id).uniq).
            group("product_colors.product_id, product_colors.color_id")
        elsif params[:type].eql?("central counter")
          @consignment_sale_products = ConsignmentSaleProduct.
            select("product_colors.product_id, product_colors.color_id").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_first}' AND consignment_sales.transaction_date <= '#{end_date_first}' THEN 1 ELSE 0 END) AS qty_sold_first").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_second}' AND consignment_sales.transaction_date <= '#{end_date_second}' THEN 1 ELSE 0 END) AS qty_sold_second").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_third}' AND consignment_sales.transaction_date <= '#{end_date_third}' THEN 1 ELSE 0 END) AS qty_sold_third").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_fourth}' AND consignment_sales.transaction_date <= '#{end_date_fourth}' THEN 1 ELSE 0 END) AS qty_sold_fourth").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_fifth}' AND consignment_sales.transaction_date <= '#{end_date_fifth}' THEN 1 ELSE 0 END) AS qty_sold_fifth").
            select("SUM(CASE WHEN consignment_sales.transaction_date >= '#{beginning_date_sixth}' AND consignment_sales.transaction_date <= '#{end_date_sixth}' THEN 1 ELSE 0 END) AS qty_sold_sixth").
            joins(:consignment_sale).
            joins(product_barcode: :product_color).
            where(:"product_colors.product_id" => @received_items.map{|x| x[:product_id]}.uniq).
            group("product_colors.product_id, product_colors.color_id")
        else
          @sale_products = SaleProduct.
            select("product_colors.product_id, product_colors.color_id").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_first.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_first.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_first").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_second.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_second.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_second").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_third.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_third.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_third").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_fourth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_fourth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_fourth").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_fifth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_fifth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_fifth").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_sixth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_sixth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_sold_sixth").
            joins(:sale).
            joins(product_barcode: :product_color).
            where(:"product_colors.product_id" => @received_items.map{|x| x[:product_id]}.uniq).
            group("product_colors.product_id, product_colors.color_id")
          
          @sales_return_products = SalesReturnProduct.
            select("product_colors.product_id, product_colors.color_id").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_first.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_first.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_first").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_second.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_second.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_second").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_third.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_third.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_third").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_fourth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_fourth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_fourth").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_fifth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_fifth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_fifth").
            select("SUM(CASE WHEN sales.transaction_time >= '#{beginning_date_sixth.beginning_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' AND sales.transaction_time <= '#{end_date_sixth.end_of_day.utc.strftime("%Y-%m-%d %H:%M:%S")}' THEN 1 ELSE 0 END) AS qty_returned_sixth").
            joins(sale_product: [:sale, product_barcode: :product_color]).
            where(:"product_colors.product_id" => @received_items.map{|x| x[:product_id]}.uniq).
            group("product_colors.product_id, product_colors.color_id")
        end
        format.js
      else
        format.html
      end
    end
  end
end
