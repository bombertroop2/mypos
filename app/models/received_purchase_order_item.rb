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
        purchase_order_detail.save
        purchase_order = purchase_order_detail.purchase_order_product.purchase_order
        warehouse = purchase_order.warehouse
        stock = warehouse.stock
        stock = Stock.new warehouse_id: warehouse.id unless stock
        product = purchase_order_detail.purchase_order_product.product
        stock_product = stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
        stock_product = stock.stock_products.build product_id: product.id unless stock_product
        stock_detail = stock_product.stock_details.select{|sd| sd.size_id.eql?(purchase_order_detail.size_id) && sd.color_id.eql?(purchase_order_detail.color_id)}.first                
        unless stock_detail
          stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity
          if stock.new_record?
            begin
              stock.save
            rescue ActiveRecord::RecordNotUnique => e
              stock = warehouse.stock.reload
              stock_product = stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
              stock_product = stock.stock_products.build product_id: product.id unless stock_product
              stock_detail = stock_product.stock_details.select{|sd| sd.size_id.eql?(purchase_order_detail.size_id) && sd.color_id.eql?(purchase_order_detail.color_id)}.first
              unless stock_detail
                stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity
                if stock_product.new_record?
                  stock_product.save
                elsif stock_detail.new_record?
                  stock_detail.save
                end
              else
                stock_detail.quantity += quantity
                stock_detail.save
              end
            end
          elsif stock_product.new_record?
            stock_product.save
          elsif stock_detail.new_record?
            stock_detail.save
          end
        else
          stock_detail.quantity += quantity
          stock_detail.save
        end                  
      end
    end
