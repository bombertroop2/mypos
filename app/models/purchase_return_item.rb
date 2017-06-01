class PurchaseReturnItem < ApplicationRecord
  attr_accessor :direct_purchase_return, :purchase_order_product_id, :purchase_order_id,
    :direct_purchase_id, :direct_purchase_product_id
  
  belongs_to :purchase_order_detail
  belongs_to :direct_purchase_detail
  belongs_to :purchase_return_product
  
  validate :item_returnable, on: :create
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true, message: "must be greater than or equal to 1"}, if: proc { |pri| pri.quantity.present? }
    validate :less_than_or_equal_to_stock, if: proc {|pri| pri.quantity.present? and pri.quantity > 0}
      
      after_create :update_stock, :update_returning_qty
          
      private
      
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
