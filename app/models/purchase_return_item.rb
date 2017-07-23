class PurchaseReturnItem < ApplicationRecord
  attr_accessor :direct_purchase_return, :purchase_order_product_id, :purchase_order_id,
    :direct_purchase_id, :direct_purchase_product_id
  
  belongs_to :purchase_order_detail
  belongs_to :direct_purchase_detail
  belongs_to :purchase_return_product
  
  validate :item_returnable, on: :create
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true, message: "must be greater than or equal to 1"}, if: proc { |pri| pri.quantity.present? }
    validate :less_than_or_equal_to_stock, if: proc {|pri| pri.quantity.present? and pri.quantity > 0}
      
      before_create :create_stock_movement
      after_create :update_stock, :update_returning_qty
          
      private
      
      def create_stock_movement
        product_id = unless direct_purchase_return
          PurchaseOrderProduct.where(id: purchase_order_product_id).select(:product_id).first.product_id
        else
          DirectPurchaseProduct.where(id: direct_purchase_product_id).select(:product_id).first.product_id
        end
        warehouse_id = unless direct_purchase_return
          PurchaseOrder.where(id: purchase_order_id).select(:warehouse_id).first.warehouse_id
        else
          DirectPurchase.where(id: direct_purchase_id).select(:warehouse_id).first.warehouse_id
        end
        current_date = Date.current
        last_movement = unless direct_purchase_return
          StockMovementProductDetail.joins(stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND last_transaction_date <= ?", product_id, purchase_order_detail.color_id, purchase_order_detail.size_id, warehouse_id, current_date.prev_month.end_of_month]).order("last_transaction_date DESC, stock_movement_product_details.id DESC").select(:ending_stock).first
        else
          StockMovementProductDetail.joins(stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND last_transaction_date <= ?", product_id, direct_purchase_detail.color_id, direct_purchase_detail.size_id, warehouse_id, current_date.prev_month.end_of_month]).order("last_transaction_date DESC, stock_movement_product_details.id DESC").select(:ending_stock).first
        end
        ending_stock = (last_movement.ending_stock rescue 0) - quantity
        stock_movement = StockMovement.select(:id).where(year: current_date.year).first
        stock_movement = StockMovement.new year: current_date.year if stock_movement.blank?
        if stock_movement.new_record?          
          stock_movement_month = stock_movement.stock_movement_months.build month: current_date.month
          stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
          stock_movement_product_detail = unless direct_purchase_return
            stock_movement_product.stock_movement_product_details.build color_id: purchase_order_detail.color_id,
              size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
              ending_stock: ending_stock, last_transaction_date: current_date
          else
            stock_movement_product.stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
              size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
              ending_stock: ending_stock, last_transaction_date: current_date
          end
          stock_movement.save
        else
          stock_movement_month = stock_movement.stock_movement_months.select{|stock_movement_month| stock_movement_month.month == current_date.month}.first
          stock_movement_month = stock_movement.stock_movement_months.build month: current_date.month if stock_movement_month.blank?
          if stock_movement_month.new_record?
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
            stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
            stock_movement_product_detail = unless direct_purchase_return
              stock_movement_product.
                stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
                ending_stock: ending_stock, last_transaction_date: current_date
            else
              stock_movement_product.
                stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
                size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
                ending_stock: ending_stock, last_transaction_date: current_date
            end
            stock_movement_month.save
          else
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select{|stock_movement_warehouse| stock_movement_warehouse.warehouse_id == warehouse_id}.first
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
            if stock_movement_warehouse.new_record?              
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
              stock_movement_product_detail = unless direct_purchase_return
                stock_movement_product.
                  stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                  size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
                  ending_stock: ending_stock, last_transaction_date: current_date
              else
                stock_movement_product.
                  stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
                  size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
                  ending_stock: ending_stock, last_transaction_date: current_date
              end
              stock_movement_warehouse.save
            else
              stock_movement_product = stock_movement_warehouse.stock_movement_products.select{|stock_movement_product| stock_movement_product.product_id == product_id}.first
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
              if stock_movement_product.new_record?                
                stock_movement_product_detail = unless direct_purchase_return
                  stock_movement_product.
                    stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                    size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
                    ending_stock: ending_stock, last_transaction_date: current_date
                else
                  stock_movement_product.
                    stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
                    size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
                    ending_stock: ending_stock, last_transaction_date: current_date
                end
                stock_movement_product.save
              else
                stock_movement_product_detail = unless direct_purchase_return
                  stock_movement_product.stock_movement_product_details.
                    select{|stock_movement_product_detail| stock_movement_product_detail.color_id == purchase_order_detail.color_id && stock_movement_product_detail.size_id == purchase_order_detail.size_id}.first
                else
                  stock_movement_product.stock_movement_product_details.
                    select{|stock_movement_product_detail| stock_movement_product_detail.color_id == direct_purchase_detail.color_id && stock_movement_product_detail.size_id == direct_purchase_detail.size_id}.first
                end
                if stock_movement_product_detail.blank?
                  stock_movement_product_detail = unless direct_purchase_return
                    stock_movement_product.
                      stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                      size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
                      ending_stock: ending_stock, last_transaction_date: current_date
                  else
                    stock_movement_product.
                      stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
                      size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_return_quantity_returned: quantity,
                      ending_stock: ending_stock, last_transaction_date: current_date
                  end
                  stock_movement_product_detail.save
                else
                  stock_movement_product_detail.with_lock do
                    stock_movement_product_detail.beginning_stock = last_movement.ending_stock rescue 0
                    stock_movement_product_detail.purchase_return_quantity_returned = stock_movement_product_detail.purchase_return_quantity_returned.to_i + quantity
                    stock_movement_product_detail.ending_stock -= quantity
                    stock_movement_product_detail.last_transaction_date = current_date
                    stock_movement_product_detail.save
                  end
                end
              end
            end
          end
        end                        
      end
      
      def item_returnable
        unless direct_purchase_return
          errors.add(:base, "Not able to return selected items") unless PurchaseOrderDetail.
            select("1 AS one").joins(purchase_order_product: :purchase_order).
            where("purchase_order_products.id = #{purchase_order_product_id} AND purchase_orders.id = #{purchase_order_id} AND purchase_order_details.id = #{purchase_order_detail_id} AND status != 'Open'").present?
        else
          errors.add(:base, "Not able to return selected items") unless DirectPurchaseDetail.
            select("1 AS one").joins(direct_purchase_product: :direct_purchase).
            where("direct_purchase_details.id = #{direct_purchase_detail_id} AND direct_purchase_products.id = #{direct_purchase_product_id} AND direct_purchases.id = #{direct_purchase_id}").present?
        end
      end
      
      def update_returning_qty
        unless direct_purchase_return
          purchase_order_detail.is_updating_returning_quantity = true
          purchase_order_detail.returning_qty = purchase_order_detail.returning_qty.to_i + quantity
          purchase_order_detail.save
        else
          direct_purchase_detail.returning_qty = direct_purchase_detail.returning_qty.to_i + quantity
          direct_purchase_detail.save
        end
      end
      
      def update_stock
        #        stock = get_stock
        @warehouse_stock.quantity -= quantity
        @warehouse_stock.save
      end
    
      def less_than_or_equal_to_stock                
        @warehouse_stock = get_stock
        warehouse_available_quantity = @warehouse_stock.quantity - @warehouse_stock.booked_quantity
        unless direct_purchase_return
          stock = purchase_order_detail.receiving_qty.to_i - purchase_order_detail.returning_qty.to_i
        else
          stock = direct_purchase_detail.quantity.to_i - direct_purchase_detail.returning_qty.to_i
        end
        errors.add(:quantity, "must be less than or equal to quantity on hand.") if quantity > stock || quantity > warehouse_available_quantity
      end
      
      def get_stock
        unless direct_purchase_return
          purchase_order_product = purchase_order_detail.purchase_order_product
          product = purchase_order_product.product
          warehouse = purchase_order_product.purchase_order.warehouse
          stock_product = warehouse.stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
          size = purchase_order_detail.size
          color = purchase_order_detail.color
          return stock_product.stock_details.select{|sd| sd.size_id.eql?(size.id) && sd.color_id.eql?(color.id)}.first
        else
          direct_purchase_product = direct_purchase_detail.direct_purchase_product
          product = direct_purchase_product.product
          warehouse = direct_purchase_product.direct_purchase.warehouse
          stock_product = warehouse.stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
          size = direct_purchase_detail.size
          color = direct_purchase_detail.color
          return stock_product.stock_details.select{|sd| sd.size_id.eql?(size.id) && sd.color_id.eql?(color.id)}.first
        end
      end
    
    end
