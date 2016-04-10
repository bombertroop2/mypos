class ReceivedPurchaseOrderItem < ActiveRecord::Base
  belongs_to :purchase_order_detail
  belongs_to :received_purchase_order_product
  
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |rpoi| rpoi.quantity.present? }
    validate :less_than_or_equal_to_order, if: proc {|rpoi| rpoi.quantity.present? and rpoi.quantity > 0}
      
      before_create :update_receiving_value, :create_stock_and_update_receiving_qty
    
      private
      
      
      def update_receiving_value
        purchase_order = received_purchase_order_product.received_purchase_order.purchase_order
        purchase_order.receiving_po = true
        purchase_order.receiving_value = purchase_order.receiving_value.to_f + received_purchase_order_product.purchase_order_product.product.cost * quantity
        purchase_order.status = if purchase_order.receiving_value != purchase_order.order_value
          "Partial"
        else
          "Finish"
        end
        purchase_order.save validate: false
      end
    
      def less_than_or_equal_to_order
        remains_quantity = purchase_order_detail.quantity - purchase_order_detail.receiving_qty.to_i
        errors.add(:quantity, "must be less than or equal to remaining ordered quantity.") if quantity > remains_quantity
      end
      
      def create_stock_and_update_receiving_qty
        purchase_order_detail.is_updating_receiving_quantity = true
        purchase_order_detail.receiving_qty = purchase_order_detail.receiving_qty.to_i + quantity
        stock = purchase_order_detail.stock
        if stock && stock.stock_type.eql?("PO")
          stock.quantity_on_hand += quantity
          stock.save
        else
          purchase_order_detail.build_stock(stock_type: "PO", quantity_on_hand: quantity)
        end
        purchase_order_detail.save
      end
    end
