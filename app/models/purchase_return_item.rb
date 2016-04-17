class PurchaseReturnItem < ActiveRecord::Base
  belongs_to :purchase_order_detail
  
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true, message: "must be greater than or equal to 1"}, if: proc { |pri| pri.quantity.present? }
    validate :less_than_or_equal_to_stock, if: proc {|pri| pri.quantity.present? and pri.quantity > 0}
      
      after_create :update_stock, :update_returning_qty
          
      private
      
      def update_returning_qty
        purchase_order_detail.is_updating_returning_quantity = true
        purchase_order_detail.returning_qty = purchase_order_detail.returning_qty.to_i + quantity
        purchase_order_detail.save
      end
      
      def update_stock
        stock = get_stock
        stock.quantity -= quantity
        stock.save
      end
    
      def less_than_or_equal_to_stock
        stock = purchase_order_detail.receiving_qty.to_i - purchase_order_detail.returning_qty.to_i
        errors.add(:quantity, "must be less than or equal to quantity on hand.") if quantity > stock
      end
      
      def get_stock
        purchase_order_product = purchase_order_detail.purchase_order_product rescue nil
        product = purchase_order_product.product rescue nil
        warehouse = purchase_order_product.purchase_order.warehouse rescue nil
        stock_product = warehouse.stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first rescue nil
        size = purchase_order_detail.size rescue nil
        color = purchase_order_detail.color rescue nil
        return stock_product.stock_details.select{|sd| sd.size_id.eql?(size.id) && sd.color_id.eql?(color.id)}.first rescue nil
      end
    
    end
