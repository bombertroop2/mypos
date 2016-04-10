class PurchaseReturnItem < ActiveRecord::Base
  belongs_to :purchase_order_detail
  
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true, message: "Quantity must be greater than or equal to 1"}, if: proc { |pri| pri.quantity.present? }
    validate :less_than_or_equal_to_stock, if: proc {|pri| pri.quantity.present? and pri.quantity > 0}
      
      after_create :update_stock
      
      attr_accessor :stock
    
      private
      
      
      def update_stock
        stock = self.stock
        stock.quantity -= quantity
        stock.save
      end
    
      def less_than_or_equal_to_stock
        self.stock = get_stock
        errors.add(:quantity, "must be less than or equal to quantity on hand.") if (stock and quantity > stock.quantity) or !stock
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
