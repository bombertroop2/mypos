class SellThrusController < ApplicationController
  def index    
    respond_to do |format|
      if params[:date].present? && (params[:counter].present? || params[:showroom].present?)
        @received_date = params[:date].to_date
        qty_sold_end_date = @received_date + 6.months - 1.day
        @warehouse = if params[:counter].present?
          Warehouse.select(:id, :code, :name).find(params[:counter])
        else
          Warehouse.select(:id, :code, :name).find(params[:showroom])
        end
        @shipment_products = ShipmentProductItem.
          select("order_booking_product_items.color_id, colors_order_booking_product_items.code AS color_code, colors_order_booking_product_items.name AS color_name, order_booking_products.product_id, products.code AS product_code, common_fields.name AS product_name, SUM(shipment_product_items.quantity) AS qty_received_per_article_color").
          joins(shipment_product: [order_booking_product: [product: :brand], shipment: :order_booking], order_booking_product_item: :color).
          where(["shipments.received_date = ? AND order_bookings.destination_warehouse_id = ?", @received_date, @warehouse.id]).
          group("order_booking_products.product_id, products.code, common_fields.name, order_booking_product_items.color_id, colors_order_booking_product_items.code, colors_order_booking_product_items.name")
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
        else
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
          end
          format.js
        else
          format.html
        end
      end
    end
  end
