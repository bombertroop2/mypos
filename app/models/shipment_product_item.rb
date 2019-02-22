class ShipmentProductItem < ApplicationRecord
  attr_accessor :order_booking_id, :order_booking_product_id, :attr_delivery_date

  audited associated_with: :shipment_product, on: [:create, :update]

  belongs_to :order_booking_product_item
  belongs_to :shipment_product
  belongs_to :price_list
  has_many :listing_stock_transactions, as: :transactionable
  validates :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 0, only_integer: true}, if: proc { |spi| spi.quantity.present? }
    validate :item_available, :price_available
    validate :quantity_available, if: proc{|spi| spi.quantity.present? && spi.quantity.is_a?(Numeric)}
      validate :transaction_after_beginning_stock_added

      before_destroy :delete_tracks, :delete_stock_movement, :delete_stock_movement_dest_warehouse, :delete_listing_stock
      before_create :update_available_quantity
      before_create :update_stock_and_booked_quantity
      after_create :create_listing_stock, :load_goods_to_destination_warehouse
      after_destroy :update_available_quantity
      
      private
      
      def update_stock_and_booked_quantity
        if @order_booking_product_item.warehouse_type.eql?("direct_sales")
          stock_item = StockDetail.joins(stock_product: [stock: :warehouse]).select(:id, :booked_quantity, :quantity).
            where(size_id: @order_booking_product_item.size_id, color_id: @order_booking_product_item.color_id).
            where("stock_products.product_id = #{@order_booking_product_item.prdct_id} AND stocks.warehouse_id = #{@order_booking_product_item.origin_warehouse_id}").
            where(["warehouses.is_active = ?", true]).first
          stock_item.with_lock do
            stock_item.booked_quantity -= @order_booking_product_item.quantity
            stock_item.quantity -= quantity
            stock_item.save
          end
        end
      end
      
      def create_listing_stock_dest_warehouse(product_id, color_id, size_id, warehouse_id, transaction_date, quantity)
        listing_stock = ListingStock.select(:id).where(warehouse_id: warehouse_id, product_id: product_id).first
        listing_stock = ListingStock.new warehouse_id: warehouse_id, product_id: product_id if listing_stock.blank?
        if listing_stock.new_record?
          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id
          listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: @do_number, transaction_type: "DO", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
          listing_stock.save
        else
          listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: color_id, size_id: size_id).select(:id).first
          listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id if listing_stock_product_detail.blank?
          if listing_stock_product_detail.new_record?
            listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: @do_number, transaction_type: "DO", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
            listing_stock_product_detail.save
          else
            listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: @do_number, transaction_type: "DO", transactionable_id: self.id, transactionable_type: self.class.name, quantity: quantity
            listing_stock_transaction.save
          end
        end
      end
      
      def create_stock_movement_dest_warehouse(product_id, color_id, size_id, warehouse_id, transaction_date, quantity)
        next_month_movements = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, product_id, color_id, size_id, transaction_date.next_month.beginning_of_month]).group(:id, :beginning_stock, :ending_stock)
        next_month_movements.each do |next_month_movement|
          next_month_movement.with_lock do
            next_month_movement.beginning_stock += quantity
            next_month_movement.ending_stock += quantity
            next_month_movement.save
          end
        end

        stock_movement = StockMovement.select(:id).where(year: transaction_date.year).first
        stock_movement = StockMovement.new year: transaction_date.year if stock_movement.blank?
        if stock_movement.new_record?
          beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
          beginning_stock = 0 if beginning_stock.nil?
          stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month
          stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
          stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
            size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
          stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_received: quantity, transaction_date: transaction_date
          stock_movement.save
        else
          stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: transaction_date.month).first
          stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month if stock_movement_month.blank?
          if stock_movement_month.new_record?
            beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
            beginning_stock = 0 if beginning_stock.nil?
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
            stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
              size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
            stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_received: quantity, transaction_date: transaction_date
            stock_movement_month.save
          else
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: warehouse_id).first
            stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
            if stock_movement_warehouse.new_record?
              beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
              beginning_stock = 0 if beginning_stock.nil?
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
              stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_received: quantity, transaction_date: transaction_date
              stock_movement_warehouse.save
            else
              stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: product_id).first
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
              if stock_movement_product.new_record?
                beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                beginning_stock = 0 if beginning_stock.nil?
                stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                  size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
                stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_received: quantity, transaction_date: transaction_date
                stock_movement_product.save
              else
                stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
                  where(color_id: color_id, size_id: size_id).first
                if stock_movement_product_detail.blank?
                  beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                  beginning_stock = 0 if beginning_stock.nil?
                  stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                    size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
                  stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_received: quantity, transaction_date: transaction_date
                  stock_movement_product_detail.save
                else
                  stock_movement_product_detail.with_lock do
                    stock_movement_product_detail.ending_stock += quantity
                    stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_received: quantity, transaction_date: transaction_date
                    stock_movement_product_detail.save
                  end
                end
              end
            end
          end
        end
      end
      
      def load_goods_to_destination_warehouse
        if quantity > 0 && @order_booking_product_item.warehouse_type.eql?("direct_sales")
          product_id = @order_booking_product_item.prdct_id
          size_id = @order_booking_product_item.size_id
          color_id = @order_booking_product_item.color_id
          stock = Stock.select(:id).where(warehouse_id: @order_booking_product_item.destination_warehouse_id).first
          stock = Stock.new warehouse_id: @order_booking_product_item.destination_warehouse_id if stock.blank?
          if stock.new_record?
            stock_product = stock.stock_products.build product_id: product_id
            stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: quantity
            stock.save
          else
            stock_product = stock.stock_products.select(:id).where(product_id: product_id).first
            stock_product = stock.stock_products.build product_id: product_id if stock_product.blank?
            if stock_product.new_record?
              stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: quantity
              stock_product.save
            else
              stock_detail = stock_product.stock_details.select(:id, :quantity).where(size_id: size_id, color_id: color_id).first
              stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: quantity if stock_detail.blank?
              if stock_detail.new_record?
                stock_detail.save
              else
                stock_detail.with_lock do
                  stock_detail.quantity += quantity
                  stock_detail.save
                end
              end
            end
          end
          create_stock_movement_dest_warehouse(product_id, color_id, size_id, @order_booking_product_item.destination_warehouse_id, @transaction_date, quantity)
          create_listing_stock_dest_warehouse(product_id, color_id, size_id, @order_booking_product_item.destination_warehouse_id, @transaction_date, quantity)
        end
      end
      
      def transaction_after_beginning_stock_added
        if @order_booking_product_item.warehouse_type.eql?("direct_sales")
          listing_stock_transaction = ListingStockTransaction.select(:transaction_date).joins(listing_stock_product_detail: :listing_stock).where(transaction_type: "BS", :"listing_stock_product_details.color_id" => @order_booking_product_item.color_id, :"listing_stock_product_details.size_id" => @order_booking_product_item.size_id, :"listing_stocks.warehouse_id" => @order_booking_product_item.destination_warehouse_id, :"listing_stocks.product_id" => @order_booking_product_item.prdct_id).first
          if listing_stock_transaction.present? && listing_stock_transaction.transaction_date > shipment_product.shipment.delivery_date
            errors.add(:base, "Sorry, you can't perform transaction on #{shipment_product.shipment.delivery_date.strftime("%d/%m/%Y")}")
          end
        end
      end
      
      def delete_listing_stock
        listing_stock_transactions.destroy_all
      end
      
      def delete_stock_movement_dest_warehouse
        if @order_booking.warehouse_type.eql?("direct_sales")
          created_movement = StockMovementTransaction.joins(stock_movement_product_detail: [stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND transaction_date = ? AND delivery_order_quantity_received = ?", @product_id, @color_id, @size_id, @order_booking.destination_warehouse_id, @transaction_date, quantity]).select(:id, :stock_movement_product_detail_id).first
          stock_movement_product_detail_deleted = false
          stock_movement_product_details = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", @order_booking.destination_warehouse_id, @product_id, @color_id, @size_id, @transaction_date.beginning_of_month]).group(:id, :beginning_stock, :ending_stock)
          stock_movement_product_details.each do |stock_movement_product_detail|
            stock_movement_product_detail.with_lock do
              if created_movement.stock_movement_product_detail_id == stock_movement_product_detail.id
                if stock_movement_product_detail.stock_movement_transactions.count(:id) == 1
                  stock_movement_product_detail_deleted = stock_movement_product_detail.destroy
                else
                  stock_movement_product_detail.ending_stock -= quantity
                  stock_movement_product_detail.save
                end
              else
                stock_movement_product_detail.beginning_stock -= quantity
                stock_movement_product_detail.ending_stock -= quantity
                stock_movement_product_detail.save
              end      
            end            
          end
          created_movement.destroy unless stock_movement_product_detail_deleted
        end
      end
      
      def delete_stock_movement
        order_booking_product_item = OrderBookingProductItem.select(:size_id, :color_id, :order_booking_product_id).where(id: order_booking_product_item_id).first
        order_booking_product = OrderBookingProduct.select(:order_booking_id, :product_id).where(id: order_booking_product_item.order_booking_product_id).first
        @product_id = order_booking_product.product_id
        @color_id = order_booking_product_item.color_id
        @size_id = order_booking_product_item.size_id
        @order_booking = OrderBooking.joins(:origin_warehouse, :destination_warehouse).select(:origin_warehouse_id, :destination_warehouse_id, "destination_warehouses_order_bookings.warehouse_type").where(id: order_booking_product.order_booking_id, :"warehouses.is_active" => true, :"destination_warehouses_order_bookings.is_active" => true).first
        warehouse_id = @order_booking.origin_warehouse_id
        shipment_product = ShipmentProduct.select(:shipment_id).where(id: shipment_product_id).first
        shipment = Shipment.select(:delivery_date).where(id: shipment_product.shipment_id).first
        @transaction_date = shipment.delivery_date
        created_movement = StockMovementTransaction.joins(stock_movement_product_detail: [stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND transaction_date = ? AND delivery_order_quantity_delivered = ?", @product_id, @color_id, @size_id, warehouse_id, @transaction_date, quantity]).select(:id, :stock_movement_product_detail_id).first
        if created_movement
          stock_movement_product_detail_deleted = false
          stock_movement_product_details = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, @product_id, @color_id, @size_id, @transaction_date.beginning_of_month]).group(:id, :beginning_stock, :ending_stock)
          stock_movement_product_details.each do |stock_movement_product_detail|
            stock_movement_product_detail.with_lock do
              if created_movement.stock_movement_product_detail_id == stock_movement_product_detail.id
                if stock_movement_product_detail.stock_movement_transactions.count(:id) == 1
                  stock_movement_product_detail_deleted = stock_movement_product_detail.destroy
                else
                  stock_movement_product_detail.ending_stock += quantity
                  stock_movement_product_detail.save
                end
              else
                stock_movement_product_detail.beginning_stock += quantity
                stock_movement_product_detail.ending_stock += quantity
                stock_movement_product_detail.save
              end      
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
          OrderBookingProductItem.joins(:size, order_booking_product: [:product, order_booking: [:origin_warehouse, :destination_warehouse]]).
            where(id: order_booking_product_item_id, order_booking_product_id: order_booking_product_id).
            where(:"order_bookings.status" => "P").
            where(:"order_bookings.id" => order_booking_id).
            where(["warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true]).
            select(:quantity, :size_id, :color_id, :origin_warehouse_id, "destination_warehouses_order_bookings.warehouse_type", "order_bookings.destination_warehouse_id", "order_booking_products.product_id AS prdct_id", "warehouses.price_code_id AS origin_warehouse_price_code_id", "sizes.size AS product_size", "products.code AS product_code").first
        else
          OrderBookingProductItem.joins(:size, order_booking_product: [:product, order_booking: [:origin_warehouse, :destination_warehouse]]).
            where(id: order_booking_product_item_id, order_booking_product_id: order_booking_product_id).
            where(:"order_bookings.status" => "F").
            where(:"order_bookings.id" => order_booking_id).
            where(["warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true]).
            select(:quantity, :size_id, :color_id, :origin_warehouse_id, "destination_warehouses_order_bookings.warehouse_type", "order_bookings.destination_warehouse_id", "order_booking_products.product_id AS prdct_id", "warehouses.price_code_id AS origin_warehouse_price_code_id", "sizes.size AS product_size", "products.code AS product_code").first
        end
        errors.add(:base, "Not able to deliver selected items") if @order_booking_product_item.blank?
      end

      def price_available
        if attr_delivery_date.present? && price_list_id.blank? && @order_booking_product_item.present?
          pl = PriceList.select(:id).joins(:product_detail).
            where(["price_lists.effective_date <= ? AND product_details.size_id = ? AND product_details.product_id = ? AND product_details.price_code_id = ?", attr_delivery_date.to_date, @order_booking_product_item.size_id, @order_booking_product_item.prdct_id, @order_booking_product_item.origin_warehouse_price_code_id]).order("price_lists.effective_date DESC").first
          if pl.blank?
            errors.add(:base, "Price (article: #{@order_booking_product_item.product_code}, size: #{@order_booking_product_item.product_size}) is not available")
          else
            self.price_list_id = pl.id
          end
        end
      end
      
      def quantity_available
        errors.add(:quantity, "cannot be greater than #{@order_booking_product_item.quantity}") if quantity > @order_booking_product_item.quantity
      end
      
      def update_available_quantity
        unless destroyed?
          unless @order_booking_product_item.warehouse_type.eql?("direct_sales")
            order_booking_product_item.with_lock do
              order_booking_product_item.shipping = true
              order_booking_product_item.update_attribute :available_quantity, quantity
            end
          end
          create_stock_movement if quantity > 0
        else
          unless @order_booking.warehouse_type.eql?("direct_sales")
            order_booking_product_item.with_lock do
              order_booking_product_item.cancel_shipment = true
              order_booking_product_item.old_available_quantity = order_booking_product_item.available_quantity
              order_booking_product_item.update_attribute :available_quantity, nil
            end
          else
            # kembalikan stok ke origin warehouse
            stock_item = StockDetail.joins(stock_product: [stock: :warehouse]).select(:id, :booked_quantity, :quantity).
              where(size_id: @size_id, color_id: @color_id).
              where("stock_products.product_id = #{@product_id} AND stocks.warehouse_id = #{@order_booking.origin_warehouse_id}").
              where(["warehouses.is_active = ?", true]).first
            stock_item.with_lock do
              stock_item.booked_quantity += order_booking_product_item.quantity
              stock_item.quantity += quantity
              stock_item.save
            end

            # buang stok dari destination warehouse
            stock_item = StockDetail.joins(stock_product: [stock: :warehouse]).select(:id, :booked_quantity, :quantity).
              where(size_id: @size_id, color_id: @color_id).
              where("stock_products.product_id = #{@product_id} AND stocks.warehouse_id = #{@order_booking.destination_warehouse_id}").
              where(["warehouses.is_active = ?", true]).first
            stock_item.with_lock do
              stock_item.quantity -= quantity
              stock_item.save
            end
          end
        end
      end
      
      def create_listing_stock
        if quantity > 0
          shipment_product = ShipmentProduct.select(:shipment_id).where(id: shipment_product_id).first
          transaction = Shipment.joins(order_booking: [:origin_warehouse, :destination_warehouse]).select(:delivery_order_number).where(id: shipment_product.shipment_id, :"warehouses.is_active" => true, :"destination_warehouses_order_bookings.is_active" => true).first
          @do_number = transaction.delivery_order_number
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
      end

      def create_stock_movement
        @product_id = product_id = @order_booking_product_item.prdct_id
        order_booking_product_item = @order_booking_product_item
        @color_id = color_id = order_booking_product_item.color_id
        @size_id = size_id = order_booking_product_item.size_id
        @warehouse_id = warehouse_id = @order_booking_product_item.origin_warehouse_id
        @transaction_date = transaction_date = shipment_product.shipment.delivery_date
        stock_movement = StockMovement.select(:id).where(year: transaction_date.year).first
        stock_movement = StockMovement.new year: transaction_date.year if stock_movement.blank?

        next_month_movements = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, product_id, color_id, size_id, transaction_date.next_month.beginning_of_month]).group(:id, :beginning_stock, :ending_stock)
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
          if beginning_stock.nil? || beginning_stock < 1
            throw :abort
          end
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
            if beginning_stock.nil? || beginning_stock < 1
              throw :abort
            end
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
              if beginning_stock.nil? || beginning_stock < 1
                throw :abort
              end
              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
              stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
              stock_movement_warehouse.save
            else
              stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: product_id).first
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
              if stock_movement_product.new_record?                          
                beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                if beginning_stock.nil? || beginning_stock < 1
                  throw :abort
                end
                stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                  size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                stock_movement_product_detail.stock_movement_transactions.build delivery_order_quantity_delivered: quantity, transaction_date: transaction_date
                stock_movement_product.save
              else
                stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
                  where(color_id: color_id, size_id: size_id).first
                if stock_movement_product_detail.blank?
                  beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                  if beginning_stock.nil? || beginning_stock < 1
                    throw :abort
                  end
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
