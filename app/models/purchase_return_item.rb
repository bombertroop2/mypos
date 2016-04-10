class PurchaseReturnItem < ActiveRecord::Base
  belongs_to :purchase_order_detail
  
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true, message: "Quantity must be greater than or equal to 1"}, if: proc { |pri| pri.quantity.present? }
    validate :less_than_or_equal_to_stock, if: proc {|pri| pri.quantity.present? and pri.quantity > 0}
      
#      after_create :update_stock
    
      private
      
      
#      def update_stock
#        stock = purchase_order_detail.stock
#        stock.quantity_on_hand = stock.quantity_on_hand - quantity
#        stock.save
#      end
    
#      def less_than_or_equal_to_stock
#        errors.add(:quantity, "Return quantity must be less than or equal to quantity on hand.") if (purchase_order_detail.stock and quantity > purchase_order_detail.stock.quantity_on_hand) or !purchase_order_detail.stock
#      end
    
    end
