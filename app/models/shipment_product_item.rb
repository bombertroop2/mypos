class ShipmentProductItem < ApplicationRecord
  attr_accessor :order_booking_id, :order_booking_product_id

  audited associated_with: :shipment_product, on: [:create, :update]

  belongs_to :order_booking_product_item
  belongs_to :shipment_product
  has_one :listing_stock_transaction, as: :transactionable
  validates :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 0, only_integer: true}, if: proc { |spi| spi.quantity.present? }
    validate :item_available
    validate :quantity_available, if: proc{|spi| spi.quantity.present? && spi.quantity.is_a?(Numeric)}
  
      before_destroy :delete_tracks, :delete_stock_movement, :delete_listing_stock
      before_create :update_available_quantity
      after_create :create_listing_stock
      after_destroy :update_available_quantity
      
      private
      
      def delete_listing_stock
        listing_stock_transaction.destroy
      end
      
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
        created_movement = StockMovementTransaction.joins(stock_movement_product_detail: [stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND transaction_date = ? AND delivery_order_quantity_delivered = ?", product_id, color_id, size_id, warehouse_id, transaction_date, quantity]).select(:id, :stock_movement_product_detail_id).first
        if created_movement
          stock_movement_product_detail_deleted = false
          stock_movement_product_details = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, product_id, color_id, size_id, transaction_date.beginning_of_month]).group(:id, :beginning_stock, :ending_stock).order("transaction_date")
          stock_movement_product_details.each do |stock_movement_product_detail|
            stock_movement_product_detail.with_lock do
              if created_movement.stock_movement_product_detail_id == stock_movement_product_detail.id
                if stock_movement_product_detail.stock_movement_transactions.count(:id) == 1
                  stock_movement_product_detail_deleted = stock_movement_product_detail.destroy
                else
                  stock_movement_product_detail.ending_stock += quantity
                end
              else
                stock_movement_product_detail.beginning_stock += quantity
                stock_movement_product_detail.ending_stock += quantity
              end      
              stock_movement_product_detail.save
            end            
          end
          created_movement.destroy unless stock_movement_product_detail_deleted
        end
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
      
      def create_listing_stock
        shipment_product = ShipmentProduct.select(:shipment_id).where(id: shipment_product_id).first
        transaction = Shipment.select(:delivery_order_number).where(id: shipment_product.shipment_id).first
        listing_stock = ListingStock.select(:id).where(warehouse_id: @warehouse_id, product_id: @product_id).first
        listing_stock = ListingStock.new warehouse_id: @warehouse_id, product_id: @product_id if listing_stock.blank?
        if listing_stock.new_record?                    
          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: @color_id, size_id: @size_id
          listing_stock_product_detail.listing_stock_transactions.build transaction_date: @transaction_date, transaction_number: transaction.delivery_order_number, transaction_type: "DO", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
          listing_stock.save
        else
          listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: @color_id, size_id: @size_id).select(:id).first
          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: @color_id, size_id: @size_id if listing_stock_product_detail.blank?
          if listing_stock_product_detail.new_record?
            listing_stock_product_detail.listing_stock_transactions.build transaction_date: @transaction_date, transaction_number: transaction.delivery_order_number, transaction_type: "DO", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
            listing_stock_product_detail.save
          else
            listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: @transaction_date, transaction_number: transaction.delivery_order_number, transaction_type: "DO", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
            listing_stock_transaction.save
          end
        end
      end

      def create_stock_movement
        @product_id = product_id = OrderBookingProduct.select(:product_id).where(id: order_booking_product_id).first.product_id
        order_booking_product_item = OrderBookingProductItem.select(:size_id, :color_id).where(id: order_booking_product_item_id).first
        @color_id = color_id = order_booking_product_item.color_id
        @size_id = size_id = order_booking_product_item.size_id
        @warehouse_id = warehouse_id = OrderBooking.select(:origin_warehouse_id).where(id: order_booking_id).first.origin_warehouse_id
        @transaction_date = transaction_date = shipment_product.shipment.delivery_date
        stock_movement = StockMovement.select(:id).where(year: transaction_date.year).first
        stock_movement = StockMovement.new year: transaction_date.year if stock_movement.blank?

        next_month_movements = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, product_id, color_id, size_id, transaction_date.next_month.beginning_of_month]).group(:id, :beginning_stock, :ending_stock).order("transaction_date")
        next_month_movements.each do |next_month_movement|
          next_month_movement.with_lock do
            next_month_movement.beginning_stock -= quantity
            next_month_movement.ending_stock -= quantity
            next_month_movement.save
          end            
        end

        if stock_movement.new_record?                    
          stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month
          stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
          beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
          beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
            size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
          stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
          stock_movement.save
        else
          stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: transaction_date.month).first
          stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month if stock_movement_month.blank?
          if stock_movement_month.new_record?                      
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
            stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
            beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
            beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
              size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
            stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
            stock_movement_month.save
          else
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: warehouse_id).first
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
            if stock_movement_warehouse.new_record?                        
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
              beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
              beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
              stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
              stock_movement_warehouse.save
            else
              stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: product_id).first
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
              if stock_movement_product.new_record?                          
                beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
                stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                  size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
                stock_movement_product.save
              else
                stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
                  where(color_id: color_id, size_id: size_id).first
                if stock_movement_product_detail.blank?
                  beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                  beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
                  stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                    size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                  stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
                  stock_movement_product_detail.save
                else
                  stock_movement_product_detail.with_lock do
                    stock_movement_product_detail.ending_stock -= quantity
                    stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
                    stock_movement_product_detail.save
                  end
                end
              end
            end
          end
        end
      end
    end
