class ShipmentReceiptProductItem < ApplicationRecord
  attr_accessor :shipment_id, :shipment_product_id

  belongs_to :shipment_receipt_product
  belongs_to :shipment_product_item
  
  validates :shipment_product_item_id, presence: true
  validate :item_available, if: proc{|shpmnt_prdct_item| shpmnt_prdct_item.shipment_product_item_id.present?}

    before_create :calculate_quantity
    after_create :update_stock, if: proc{|srpi| srpi.quantity != 0}
      after_create :empty_in_transit_warehouse

      private
    
      def calculate_quantity
        self.quantity = shipment_product_item.quantity
      end

      def item_available
        errors.add(:shipment_product_item_id, "does not exist!") if ShipmentProductItem.
          joins(shipment_product: :shipment).select("1 AS one").where(id: shipment_product_item_id).
          where(["received_date IS NULL AND shipment_product_id = ? AND shipment_id = ?", shipment_product_id, shipment_id]).blank?
      end
    
      def update_stock
        warehouse = shipment_product_item.shipment_product.shipment.order_booking.destination_warehouse
        stock = warehouse.stock
        stock = Stock.new warehouse_id: warehouse.id unless stock
        product = shipment_product_item.shipment_product.order_booking_product.product
        stock_product = stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
        stock_product = stock.stock_products.build product_id: product.id unless stock_product
        stock_detail = stock_product.stock_details.select{|sd| sd.size_id.eql?(shipment_product_item.order_booking_product_item.size_id) && sd.color_id.eql?(shipment_product_item.order_booking_product_item.color_id)}.first
        unless stock_detail
          stock_detail = stock_product.stock_details.build size_id: shipment_product_item.order_booking_product_item.size_id, color_id: shipment_product_item.order_booking_product_item.color_id, quantity: quantity
          if stock.new_record?
            begin
              stock.save
            rescue ActiveRecord::RecordNotUnique => e
              stock = warehouse.stock.reload
              stock_product = stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
              stock_product = stock.stock_products.build product_id: product.id unless stock_product
              stock_detail = stock_product.stock_details.select{|sd| sd.size_id.eql?(shipment_product_item.order_booking_product_item.size_id) && sd.color_id.eql?(shipment_product_item.order_booking_product_item.color_id)}.first
              unless stock_detail
                stock_detail = stock_product.stock_details.build size_id: shipment_product_item.order_booking_product_item.size_id, color_id: shipment_product_item.order_booking_product_item.color_id, quantity: quantity
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
      
      def empty_in_transit_warehouse
        order_booking_product_item = shipment_product_item.order_booking_product_item
        order_booking_product_item.update_attribute :available_quantity, nil
      end
    end
