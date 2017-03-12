class PurchaseReturnItem < ApplicationRecord
  attr_accessor :direct_purchase_return
  
  belongs_to :purchase_order_detail
  belongs_to :direct_purchase_detail
  belongs_to :purchase_return_product
  
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true, message: "must be greater than or equal to 1"}, if: proc { |pri| pri.quantity.present? }
    validate :less_than_or_equal_to_stock, if: proc {|pri| pri.quantity.present? and pri.quantity > 0}
      
      after_create :update_stock, :update_returning_qty
          
      private
      
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
        stock = get_stock
        stock.quantity -= quantity
        stock.save
      end
    
      def less_than_or_equal_to_stock
        unless direct_purchase_return
          stock = purchase_order_detail.receiving_qty.to_i - purchase_order_detail.returning_qty.to_i
        else
          stock = direct_purchase_detail.quantity.to_i - direct_purchase_detail.returning_qty.to_i
        end
        errors.add(:quantity, "must be less than or equal to quantity on hand.") if quantity > stock
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
          #          purchase_order_product = purchase_order_detail.purchase_order_product rescue nil
          product = purchase_return_product.direct_purchase_product.product
          warehouse = purchase_return_product.direct_purchase_product.direct_purchase.warehouse
          stock_product = warehouse.stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
          size = direct_purchase_detail.size
          color = direct_purchase_detail.color
          return stock_product.stock_details.select{|sd| sd.size_id.eql?(size.id) && sd.color_id.eql?(color.id)}.first
        end
      end
    
    end
