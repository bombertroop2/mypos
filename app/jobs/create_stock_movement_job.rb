# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class CreateStockMovementJob < ApplicationJob
  queue_as :default
  def perform(warehouse_id, product_id, color_id, size_id, transaction_date, quantity)
    transaction_date = transaction_date.to_date
    next_month_movements = StockMovementProductDetail.
      joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).
      select(:id, :beginning_stock, :ending_stock).
      where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, product_id, color_id, size_id, transaction_date.next_month.beginning_of_month]).
      group(:id, :beginning_stock, :ending_stock)
    next_month_movements.each do |next_month_movement|
      next_month_movement.with_lock do
        next_month_movement.beginning_stock += quantity
        next_month_movement.ending_stock += quantity
        next_month_movement.save
      end            
    end

    stock_movement = StockMovement.select(:id).where(year: transaction_date.year).first
    stock_movement = StockMovement.new year: transaction_date.year if stock_movement.blank?
    if stock_movement.new_record?                    
      stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month
      stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
      stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
      beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
      beginning_stock = 0 if beginning_stock.nil?
      stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
        size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
      stock_movement_product_detail.stock_movement_transactions.build purchase_order_quantity_received: quantity, transaction_date: transaction_date
      stock_movement.save
    else
      stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: transaction_date.month).first
      stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month if stock_movement_month.blank?
      if stock_movement_month.new_record?                      
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
        stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
        beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
        beginning_stock = 0 if beginning_stock.nil?                        
        stock_movement_product_detail = stock_movement_product.
          stock_movement_product_details.build color_id: color_id,
          size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
        stock_movement_product_detail.stock_movement_transactions.build purchase_order_quantity_received: quantity, transaction_date: transaction_date
        stock_movement_month.save
      else
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: warehouse_id.to_i).first
        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
        if stock_movement_warehouse.new_record?                        
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
          beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
          beginning_stock = 0 if beginning_stock.nil?                        
          stock_movement_product_detail = stock_movement_product.
            stock_movement_product_details.build color_id: color_id,
            size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
          stock_movement_product_detail.stock_movement_transactions.build purchase_order_quantity_received: quantity, transaction_date: transaction_date
          stock_movement_warehouse.save
        else
          stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: product_id.to_i).first
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
          if stock_movement_product.new_record?                          
            beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
            beginning_stock = 0 if beginning_stock.nil?                        
            stock_movement_product_detail = stock_movement_product.
              stock_movement_product_details.build color_id: color_id,
              size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
            stock_movement_product_detail.stock_movement_transactions.build purchase_order_quantity_received: quantity, transaction_date: transaction_date
            stock_movement_product.save
          else
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
              where(color_id: color_id, size_id: size_id).first
            if stock_movement_product_detail.blank?
              beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
              beginning_stock = 0 if beginning_stock.nil?                        
              stock_movement_product_detail = stock_movement_product.
                stock_movement_product_details.build color_id: color_id,
                size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
              stock_movement_product_detail.stock_movement_transactions.build purchase_order_quantity_received: quantity, transaction_date: transaction_date
              stock_movement_product_detail.save
            else
              stock_movement_product_detail.with_lock do
                stock_movement_product_detail.ending_stock += quantity
                stock_movement_product_detail.stock_movement_transactions.build purchase_order_quantity_received: quantity, transaction_date: transaction_date
                stock_movement_product_detail.save
              end
            end
          end
        end
      end
    end
  end
end