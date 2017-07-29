class ShipmentProductItem < ApplicationRecord
  attr_accessor :order_booking_id, :order_booking_product_id

  audited associated_with: :shipment_product, on: [:create, :update]

  belongs_to :order_booking_product_item
  belongs_to :shipment_product
  validates :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 0, only_integer: true}, if: proc { |spi| spi.quantity.present? }
    validate :item_available
    validate :quantity_available, if: proc{|spi| spi.quantity.present? && spi.quantity.is_a?(Numeric)}
  
      before_destroy :delete_tracks, :delete_stock_movement
      before_create :update_available_quantity
      after_destroy :update_available_quantity
      
      private
      
      def delete_stock_movement
        order_booking_product_item = OrderBookingProductItem.select(:size_id, :color_id, :order_booking_product_id).where(id: order_booking_product_item_id).first
        order_booking_product = OrderBookingProduct.select(:order_booking_id, :product_id).where(id: order_booking_product_item.order_booking_product_id).first
        product_id = order_booking_product.product_id
        color_id = order_booking_product_item.color_id
        size_id = order_booking_product_item.size_id
        warehouse_id = OrderBooking.select(:origin_warehouse_id).where(id: order_booking_product.order_booking_id).first.origin_warehouse_id
        shipment_product = ShipmentProduct.select(:shipment_id).where(id: shipment_product_id).first
        shipment = Shipment.select(:delivery_date).where(id: shipment_product.shipment_id).first
        transaction_date = shipment.delivery_date
        created_movement = StockMovementTransaction.joins(stock_movement_product_detail: [stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND transaction_date = ? AND delivery_order_quantity_delivered = ?", product_id, color_id, size_id, warehouse_id, transaction_date, quantity]).select(:id).first
        created_movement.destroy if created_movement
      end
        
      def delete_tracks
        audits.destroy_all
      end
  
      def item_available
        @order_booking_product_item = if new_record?
          OrderBookingProductItem.joins(order_booking_product: :order_booking).
            where(id: order_booking_product_item_id, order_booking_product_id: order_booking_product_id).
            where(:"order_bookings.status" => "P").
            where(:"order_bookings.id" => order_booking_id).
            select(:quantity).first
        else
          OrderBookingProductItem.joins(order_booking_product: :order_booking).
            where(id: order_booking_product_item_id, order_booking_product_id: order_booking_product_id).
            where(:"order_bookings.status" => "F").
            where(:"order_bookings.id" => order_booking_id).
            select(:quantity).first
        end
        errors.add(:base, "Not able to deliver selected items") if @order_booking_product_item.blank?
      end
      
      def quantity_available        
        errors.add(:quantity, "cannot be greater than #{@order_booking_product_item.quantity}") if quantity > @order_booking_product_item.quantity
      end
      
      def update_available_quantity
        unless destroyed?
          order_booking_product_item.shipping = true
          order_booking_product_item.update_attribute :available_quantity, quantity
          create_stock_movement if quantity > 0
        else
          order_booking_product_item.cancel_shipment = true
          order_booking_product_item.old_available_quantity = order_booking_product_item.available_quantity
          order_booking_product_item.update_attribute :available_quantity, nil
        end
      end

      def create_stock_movement
        product_id = OrderBookingProduct.select(:product_id).where(id: order_booking_product_id).first.product_id
        order_booking_product_item = OrderBookingProductItem.select(:size_id, :color_id).where(id: order_booking_product_item_id).first
        color_id = order_booking_product_item.color_id
        size_id = order_booking_product_item.size_id
        warehouse_id = OrderBooking.select(:origin_warehouse_id).where(id: order_booking_id).first.origin_warehouse_id
        transaction_date = shipment_product.shipment.delivery_date
        stock_movement = StockMovement.select(:id).where(year: transaction_date.year).first
        stock_movement = StockMovement.new year: transaction_date.year if stock_movement.blank?
        if stock_movement.new_record?                    
          stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month
          stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
            size_id: size_id
          stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
          stock_movement.save
        else
          stock_movement_month = stock_movement.stock_movement_months.select{|stock_movement_month| stock_movement_month.month == transaction_date.month}.first
          stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month if stock_movement_month.blank?
          if stock_movement_month.new_record?                      
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
            stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
              size_id: size_id
            stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
            stock_movement_month.save
          else
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select{|stock_movement_warehouse| stock_movement_warehouse.warehouse_id == warehouse_id}.first
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
            if stock_movement_warehouse.new_record?                        
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                size_id: size_id
              stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
              stock_movement_warehouse.save
            else
              stock_movement_product = stock_movement_warehouse.stock_movement_products.select{|stock_movement_product| stock_movement_product.product_id == product_id}.first
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
              if stock_movement_product.new_record?                          
                stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                  size_id: size_id
                stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
                stock_movement_product.save
              else
                stock_movement_product_detail = stock_movement_product.stock_movement_product_details.
                  select{|stock_movement_product_detail| stock_movement_product_detail.color_id == color_id && stock_movement_product_detail.size_id == size_id}.first
                if stock_movement_product_detail.blank?
                  stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                    size_id: size_id
                  stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
                  stock_movement_product_detail.save
                else
                  stock_movement_transaction = stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
                  stock_movement_transaction.save
                end
              end
            end
          end
        end
      end
    end
