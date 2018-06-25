class Shipment < ApplicationRecord
  audited on: [:create, :update]
  has_associated_audits

  attr_accessor :order_booking_number, :receiving_inventory, :attr_change_receive_date
  
  belongs_to :order_booking
  belongs_to :courier
  
  has_many :shipment_products, dependent: :destroy

  accepts_nested_attributes_for :shipment_products, allow_destroy: true#, reject_if: :child_blank
    
  validates :delivery_date, :courier_id, :order_booking_id, presence: true
  validates :delivery_date, date: {after_or_equal_to: proc {|shpmnt| shpmnt.order_booking.created_at.to_date}, message: 'must be after or equal to creation date of order booking' }, if: proc {|shpmnt| shpmnt.delivery_date.present? && shpmnt.order_booking_id.present? && !shpmnt.attr_change_receive_date}
    validates :delivery_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|shpmnt| shpmnt.delivery_date.present? && !shpmnt.receiving_inventory && !shpmnt.attr_change_receive_date}
      validate :warehouse_is_active, :courier_available, :order_booking_available#, :check_min_quantity
      validate :editable, on: :update, if: proc{|shpmnt| !shpmnt.receiving_inventory && !shpmnt.attr_change_receive_date}
        validate :order_booking_not_changed, on: :update, if: proc{|shipment| shipment.order_booking_id_changed?}
          validates :received_date, presence: true, if: proc{|shpmnt| shpmnt.receiving_inventory || shpmnt.attr_change_receive_date}
            validates :received_date, date: {before_or_equal_to: Proc.new { Date.current }, message: 'must be before or equal to today' }, if: proc {|shpmnt| shpmnt.received_date.present? && (shpmnt.receiving_inventory || shpmnt.attr_change_receive_date)}
              validates :received_date, date: {after_or_equal_to: proc {|shpmnt| shpmnt.delivery_date}, message: 'must be after or equal to delivery date' }, if: proc {|shpmnt| shpmnt.received_date.present? && (shpmnt.receiving_inventory || shpmnt.attr_change_receive_date)}
                validate :new_received_date_valid, if: proc {|shpmnt| shpmnt.received_date.present? && shpmnt.attr_change_receive_date}
                  validate :shipment_receivable, if: proc{|shpmnt| shpmnt.receiving_inventory}
                    validate :minimum_quantity, if: proc{|shpmnt| !shpmnt.receiving_inventory && !shpmnt.attr_change_receive_date}
                      validate :transaction_open, if: proc{|shipment| shipment.receiving_inventory || shipment.attr_change_receive_date}
                        validate :receive_date_not_changed, if: proc{|shipment| shipment.attr_change_receive_date}

                          before_create :generate_do_number
                          after_create :finish_ob, :notify_store
                          before_destroy :deletable, :transaction_open, :delete_tracks
                          after_destroy :set_ob_status_to_p
                          before_update :set_is_receive_date_changed, :change_listing_stock_transaction_date, if: proc{|shipment| shipment.attr_change_receive_date}
                            after_update :empty_in_transit_warehouse, :load_goods_to_destination_warehouse, if: proc{|shpmnt| shpmnt.receiving_inventory}


                              private
                              
                              def change_listing_stock_transaction_date
                                if received_date != received_date_was
                                  warehouse_id = order_booking.destination_warehouse_id
                                  shipment_products.joins(:order_booking_product).select(:id, "order_booking_products.product_id").each do |shipment_product|
                                    shipment_product.shipment_product_items.joins(:order_booking_product_item).select(:id, :quantity, "order_booking_product_items.size_id, order_booking_product_items.color_id").each do |shipment_product_item|
                                      if shipment_product_item.quantity > 0
                                        listing_stock_transaction = ListingStockTransaction.joins(listing_stock_product_detail: :listing_stock).select(:id, :transaction_date).where(["transaction_date = ? AND transaction_number = ? AND transaction_type = ? AND transactionable_id = ? AND transactionable_type = ? AND listing_stocks.warehouse_id = ?", received_date_was, delivery_order_number, "DO", shipment_product_item.id, shipment_product_item.class.name, warehouse_id]).first
                                        listing_stock_transaction.with_lock do
                                          listing_stock_transaction.transaction_date = received_date
                                          listing_stock_transaction.save
                                        end     
                                        delete_stock_movement(shipment_product.product_id, shipment_product_item.color_id, shipment_product_item.size_id, warehouse_id, received_date_was, shipment_product_item.quantity)
                                        create_stock_movement(shipment_product.product_id, shipment_product_item.color_id, shipment_product_item.size_id, warehouse_id, received_date, shipment_product_item.quantity)
                                      end
                                    end
                                  end
                                end
                              end
                              
                              def set_is_receive_date_changed
                                if received_date != received_date_was
                                  self.is_receive_date_changed = true
                                end
                              end
                          
                              def receive_date_not_changed
                                if is_receive_date_changed_was
                                  errors.add(:base, "Sorry, receive date is already changed")
                                elsif received_date_was.blank?
                                  errors.add(:base, "Sorry, inventory #{delivery_order_number} is not received yet")
                                end
                              end
                          
                              def new_received_date_valid
                                errors.add(:base, "Receive date must be before or equal to #{received_date_was.strftime("%d/%m/%Y")}") if received_date_was.present? && received_date > received_date_was
                              end
                        
                              def warehouse_is_active
                                if order_booking_id.present?
                                  @order_booking = OrderBooking.select(:id, :status, :origin_warehouse_id, :destination_warehouse_id).where(id: order_booking_id).first
                                  if @order_booking.present?
                                    origin_warehouse = Warehouse.select(:id).where(id: @order_booking.origin_warehouse_id, is_active: true).first
                                    if origin_warehouse.blank?
                                      errors.add(:base, "Sorry, origin warehouse is not active")
                                    else
                                      @destination_warehouse = Warehouse.select(:id, :code).where(id: @order_booking.destination_warehouse_id, is_active: true).first
                                      errors.add(:base, "Sorry, destination warehouse is not active") if @destination_warehouse.blank?
                                    end
                                  end
                                end
                              end
                        
                              def create_listing_stock(product_id, color_id, size_id, warehouse_id, transaction_date, quantity, shipment_product, shipment_product_item)
                                transaction = Shipment.select(:delivery_order_number).where(id: shipment_product.shipment_id).first
                                listing_stock = ListingStock.select(:id).where(warehouse_id: warehouse_id, product_id: product_id).first
                                listing_stock = ListingStock.new warehouse_id: warehouse_id, product_id: product_id if listing_stock.blank?
                                if listing_stock.new_record?                    
                                  listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id
                                  listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: transaction.delivery_order_number, transaction_type: "DO", transactionable_id: shipment_product_item.id, transactionable_type: shipment_product_item.class.name, quantity: quantity
                                  listing_stock.save
                                else
                                  listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: color_id, size_id: size_id).select(:id).first
                                  listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id if listing_stock_product_detail.blank?
                                  if listing_stock_product_detail.new_record?
                                    listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: transaction.delivery_order_number, transaction_type: "DO", transactionable_id: shipment_product_item.id, transactionable_type: shipment_product_item.class.name, quantity: quantity
                                    listing_stock_product_detail.save
                                  else
                                    listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: transaction.delivery_order_number, transaction_type: "DO", transactionable_id: shipment_product_item.id, transactionable_type: shipment_product_item.class.name, quantity: quantity
                                    listing_stock_transaction.save
                                  end
                                end
                              end
                        
                              def create_stock_movement(product_id, color_id, size_id, warehouse_id, transaction_date, quantity)
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
                                  beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
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
                                    beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
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
                                      beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
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
                                        beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
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
                                          beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
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
                      
                              def transaction_open
                                unless receiving_inventory
                                  if FiscalYear.joins(:fiscal_months).where(year: delivery_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[delivery_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                                    errors.add(:base, "Sorry, you can't perform this transaction")
                                    throw :abort
                                  end
                                else
                                  errors.add(:base, "Sorry, you can't perform this transaction") if FiscalYear.joins(:fiscal_months).where(year: received_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[received_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                                end
                              end
                      
                              def minimum_quantity                        
                                errors.add(:base, "Shipment must have at least one item") if quantity == 0
                              end
                    
                              def load_goods_to_destination_warehouse
                                destination_warehouse_id = if @order_booking.present?
                                  @order_booking.destination_warehouse_id
                                else
                                  order_booking.destination_warehouse_id
                                end
                                stock = Stock.select(:id).where(warehouse_id: destination_warehouse_id).first
                                stock = Stock.new warehouse_id: destination_warehouse_id if stock.blank?
                                if stock.new_record?
                                  shipment_products.select(:id, :order_booking_product_id, :shipment_id).each do |shipment_product|
                                    product_id = shipment_product.order_booking_product.product_id
                                    stock_product = stock.stock_products.build product_id: product_id
                                    shipment_product.shipment_product_items.select(:id, :order_booking_product_item_id, :quantity).each do |shipment_product_item|
                                      if shipment_product_item.quantity > 0
                                        size_id = shipment_product_item.order_booking_product_item.size_id
                                        color_id = shipment_product_item.order_booking_product_item.color_id
                                        stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: shipment_product_item.quantity
                                        create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, shipment_product_item.quantity)
                                        create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, shipment_product_item.quantity, shipment_product, shipment_product_item)
                                      end
                                    end
                                  end
                                  stock.save
                                else
                                  shipment_products.select(:id, :order_booking_product_id, :shipment_id).each do |shipment_product|
                                    product_id = shipment_product.order_booking_product.product_id
                                    stock_product = stock.stock_products.select{|stock_product| stock_product.product_id == product_id}.first
                                    stock_product = stock.stock_products.build product_id: product_id if stock_product.blank?
                                    if stock_product.new_record?
                                      shipment_product.shipment_product_items.select(:id, :order_booking_product_item_id, :quantity).each do |shipment_product_item|
                                        if shipment_product_item.quantity > 0
                                          size_id = shipment_product_item.order_booking_product_item.size_id
                                          color_id = shipment_product_item.order_booking_product_item.color_id
                                          stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: shipment_product_item.quantity
                                          create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, shipment_product_item.quantity)
                                          create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, shipment_product_item.quantity, shipment_product, shipment_product_item)
                                        end
                                      end
                                      stock_product.save
                                    else
                                      shipment_product.shipment_product_items.select(:id, :order_booking_product_item_id, :quantity).each do |shipment_product_item|
                                        if shipment_product_item.quantity > 0
                                          size_id = shipment_product_item.order_booking_product_item.size_id
                                          color_id = shipment_product_item.order_booking_product_item.color_id
                                          stock_detail = stock_product.stock_details.select{|stock_detail| stock_detail.size_id == size_id && stock_detail.color_id == color_id}.first
                                          stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: shipment_product_item.quantity if stock_detail.blank?
                                          if stock_detail.new_record?                                      
                                            create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, shipment_product_item.quantity)
                                            create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, shipment_product_item.quantity, shipment_product, shipment_product_item)
                                            stock_detail.save
                                          else
                                            stock_detail.with_lock do
                                              stock_detail.quantity += shipment_product_item.quantity
                                              stock_detail.save
                                            end
                                            create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, shipment_product_item.quantity)
                                            create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, shipment_product_item.quantity, shipment_product, shipment_product_item)
                                          end
                                        end
                                      end
                                    end
                                  end
                                end
                              end
                  
                              def empty_in_transit_warehouse
                                shipment_products.select(:id).each do |shipment_product|
                                  shipment_product.shipment_product_items.select(:order_booking_product_item_id).each do |shipment_product_item|
                                    order_booking_product_item = shipment_product_item.order_booking_product_item
                                    order_booking_product_item.with_lock do
                                      order_booking_product_item.update_attribute :available_quantity, nil if order_booking_product_item.available_quantity.present?
                                    end
                                  end
                                end
                              end
                  
                              def shipment_receivable
                                errors.add(:base, "Sorry, inventory #{delivery_order_number} is already received") if received_date_was.present?
                              end
      
                              def order_booking_not_changed        
                                errors.add(:order_booking_id, "cannot be changed")
                              end
      
                              def editable
                                errors.add(:base, "The record cannot be edited") if received_date.present?
                              end
      
                              def notify_store
                                destination_warehouse = if @destination_warehouse.present?
                                  @destination_warehouse
                                else
                                  order_booking.destination_warehouse
                                end
                                notification = Notification.new(event: "New Notification", body: "Shipment #{delivery_order_number} will arrive soon")
                                destination_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
                                  notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
                                end
                                notification.save
                              end
      
                              def delete_tracks
                                audits.destroy_all
                              end
  
                              def set_ob_status_to_p
                                order_booking.without_auditing do
                                  order_booking.update_attribute :status, "P"
                                end
                              end
      
                              def deletable
                                if received_date.present?
                                  errors.add(:base, "The record cannot be deleted")
                                  throw :abort
                                end 
                              end
    
                              def courier_available
                                errors.add(:courier_id, "does not exist!") if (new_record? || (courier_id_changed? && persisted?)) && courier_id.present? && Courier.where(id: courier_id).select("1 AS one").blank?
                              end
    
                              def order_booking_available
                                if (new_record? || (order_booking_id_changed? && persisted?)) && order_booking_id.present?
                                  is_ob_printed = if @order_booking.present?
                                    @order_booking.status.eql?("P")
                                  else
                                    OrderBooking.where(id: order_booking_id).printed.select("1 AS one").present?
                                  end
                                  errors.add(:order_booking_id, "does not exist!") unless is_ob_printed
                                end
                              end
  
                              def child_blank(attributed)
                                attributed[:shipment_product_items_attributes].each do |key, value| 
                                  return false if value[:quantity].present?
                                end
      
                                return true
                              end
    
                              #      def check_min_quantity
                              #        if new_record?
                              #          errors.add(:base, "Shipment must have at least one piece of product") if shipment_products.blank?
                              #        end
                              #      end
    
                              def generate_do_number
                                destination_warehouse_id = if @order_booking.present?
                                  @order_booking.destination_warehouse_id
                                else
                                  order_booking.destination_warehouse_id
                                end
                          
                                full_warehouse_code = if @destination_warehouse.present?
                                  @destination_warehouse.code
                                else
                                  Warehouse.select(:code).where(id: destination_warehouse_id, is_active: true).first.code
                                end
                          
                                warehouse_code = full_warehouse_code.split("-")[0]
                                today = Date.current
                                current_month = today.month.to_s.rjust(2, '0')
                                current_year = today.strftime("%y").rjust(2, '0')
                                existed_numbers = Shipment.where("delivery_order_number LIKE '#{warehouse_code}SJ#{current_month}#{current_year}%'").select(:delivery_order_number).order(:delivery_order_number)
                                if existed_numbers.blank?
                                  new_number = "#{warehouse_code}SJ#{current_month}#{current_year}0001"
                                else
                                  if existed_numbers.length == 1
                                    seq_number = existed_numbers[0].delivery_order_number.split("#{warehouse_code}SJ#{current_month}#{current_year}").last
                                    if seq_number.to_i > 1
                                      new_number = "#{warehouse_code}SJ#{current_month}#{current_year}0001"
                                    else
                                      new_number = "#{warehouse_code}SJ#{current_month}#{current_year}#{seq_number.succ}"
                                    end
                                  else
                                    last_seq_number = ""
                                    existed_numbers.each_with_index do |existed_number, index|
                                      seq_number = existed_number.delivery_order_number.split("#{warehouse_code}SJ#{current_month}#{current_year}").last
                                      if seq_number.to_i > 1 && index == 0
                                        new_number = "#{warehouse_code}SJ#{current_month}#{current_year}0001"
                                        break                              
                                      elsif last_seq_number.eql?("")
                                        last_seq_number = seq_number
                                      elsif (seq_number.to_i - last_seq_number.to_i) > 1
                                        new_number = "#{warehouse_code}SJ#{current_month}#{current_year}#{last_seq_number.succ}"
                                        break
                                      elsif index == existed_numbers.length - 1
                                        new_number = "#{warehouse_code}SJ#{current_month}#{current_year}#{seq_number.succ}"
                                      else
                                        last_seq_number = seq_number
                                      end
                                    end
                                  end                        
                                end

                                self.delivery_order_number = new_number
                              end
    
                              def finish_ob
                                order_booking.without_auditing do
                                  order_booking.update_attribute :status, "F"
                                end
                              end
                              
                              def delete_stock_movement(product_id, color_id, size_id, warehouse_id, transaction_date, quantity)
                                created_movement = StockMovementTransaction.joins(stock_movement_product_detail: [stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND transaction_date = ? AND delivery_order_quantity_received = ?", product_id, color_id, size_id, warehouse_id, transaction_date, quantity]).select(:id, :stock_movement_product_detail_id).first
                                if created_movement
                                  stock_movement_product_detail_deleted = false
                                  stock_movement_product_details = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, product_id, color_id, size_id, transaction_date.beginning_of_month]).group(:id, :beginning_stock, :ending_stock)
                                  stock_movement_product_details.each do |stock_movement_product_detail|
                                    stock_movement_product_detail.with_lock do
                                      if created_movement.stock_movement_product_detail_id == stock_movement_product_detail.id
                                        if stock_movement_product_detail.stock_movement_transactions.count(:id) == 1
                                          stock_movement_product_detail_deleted = stock_movement_product_detail.destroy
                                        else
                                          stock_movement_product_detail.ending_stock -= quantity
                                        end
                                      else
                                        stock_movement_product_detail.beginning_stock -= quantity
                                        stock_movement_product_detail.ending_stock -= quantity
                                      end      
                                      stock_movement_product_detail.save
                                    end            
                                  end
                                  created_movement.destroy unless stock_movement_product_detail_deleted
                                end
                              end
                            end
