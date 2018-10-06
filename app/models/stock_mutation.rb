class StockMutation < ApplicationRecord
  attr_accessor :mutation_type, :approving_mutation, :receiving_inventory_to_store, :receiving_inventory_to_warehouse, :product_code, :attr_change_receive_date

  audited on: [:create, :update]
  has_associated_audits

  belongs_to :courier
  belongs_to :origin_warehouse, class_name: "Warehouse", foreign_key: :origin_warehouse_id
  belongs_to :destination_warehouse, class_name: "Warehouse", foreign_key: :destination_warehouse_id
  has_many :stock_mutation_products, dependent: :destroy

  accepts_nested_attributes_for :stock_mutation_products, allow_destroy: true

  validates :delivery_date, :courier_id, :origin_warehouse_id, :destination_warehouse_id, presence: true
  validates :delivery_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|shpmnt| shpmnt.delivery_date.present? && shpmnt.delivery_date_changed? && !shpmnt.receiving_inventory_to_store && !shpmnt.receiving_inventory_to_warehouse && !shpmnt.attr_change_receive_date}
    validate :courier_available, :origin_warehouse_available
    validate :destination_warehouse_available, unless: proc {|sm| sm.receiving_inventory_to_warehouse}
      validate :editable, on: :update, if: proc{|sm| !sm.approving_mutation && !sm.receiving_inventory_to_store && !sm.receiving_inventory_to_warehouse && !sm.attr_change_receive_date}
        validate :approvable, if: proc{|sm| sm.approving_mutation}
          validates :received_date, presence: true, if: proc{|sm| sm.receiving_inventory_to_store || sm.receiving_inventory_to_warehouse || sm.attr_change_receive_date}
            validates :received_date, date: {before_or_equal_to: Proc.new { Date.current }, message: 'must be before or equal to today' }, if: proc {|sm| sm.received_date.present? && (sm.receiving_inventory_to_store || sm.receiving_inventory_to_warehouse || sm.attr_change_receive_date)}
              validates :received_date, date: {after_or_equal_to: proc {|sm| sm.approved_date}, message: 'must be after or equal to approved date' }, if: proc {|sm| sm.received_date.present? && (sm.receiving_inventory_to_store || sm.attr_change_receive_date)}
                validates :received_date, date: {after_or_equal_to: proc {|sm| sm.delivery_date}, message: 'must be after or equal to delivery date' }, if: proc {|sm| sm.received_date.present? && sm.receiving_inventory_to_warehouse}
                  validate :shipment_receivable, if: proc{|sm| sm.receiving_inventory_to_store || sm.receiving_inventory_to_warehouse}
                    validate :transaction_open, if: proc{|sm| sm.receiving_inventory_to_store || sm.receiving_inventory_to_warehouse || sm.approving_mutation || sm.attr_change_receive_date}
                      validate :new_received_date_valid, if: proc {|sm| sm.received_date.present? && sm.attr_change_receive_date}
                        validate :receive_date_not_changed, if: proc{|sm| sm.attr_change_receive_date}
                          validate :article_sex_not_valid, if: proc{|sm| sm.destination_warehouse_id_changed? && sm.persisted?}
                          
                            before_create :generate_number
                            before_destroy :transaction_open, :prevent_delete_if_mutation_approved, :delete_tracks
                            before_update :apologize_to_previous_destination_store, if: proc{|sm| !sm.destination_warehouse.warehouse_type.eql?("central") && sm.destination_warehouse_id_changed?}
                              before_update :set_is_receive_date_changed, :change_listing_stock_transaction_date, if: proc{|sm| sm.attr_change_receive_date}
                                before_update :delete_old_products, if: proc{|sm| sm.mutation_type.eql?("store to store") && sm.origin_warehouse_id_changed? && sm.persisted?}
                                  after_create :notify_origin_store, :notify_destination_store, unless: proc {|sm| sm.destination_warehouse.warehouse_type.eql?("central")}
                                    after_create :notify_warehouse, if: proc {|sm| sm.destination_warehouse.warehouse_type.eql?("central")}
                                      after_update :notify_new_warehouse, if: proc {|sm| sm.destination_warehouse.warehouse_type.eql?("central") && sm.destination_warehouse_id_changed?}
                                        after_update :notify_new_destination_store, if: proc {|sm| !sm.destination_warehouse.warehouse_type.eql?("central") && sm.destination_warehouse_id_changed?}
                                          after_update :update_stock, if: proc {|sm| sm.approving_mutation}
                                            after_update :load_goods_to_destination_warehouse, if: proc{|sm| sm.receiving_inventory_to_store || sm.receiving_inventory_to_warehouse}

                                              private
                                            
                                              def article_sex_not_valid
                                                stock_mutation_products.each do |smp|
                                                  if !smp._destroy
                                                    product = Product.select(:code, :sex, "common_fields.name AS goods_type_name").joins(:goods_type).find(smp.product_id)
                                                    if product.present? && !product.sex.downcase.eql?("unisex")
                                                      dest_warehouse = Warehouse.select(:code, :counter_type).find(destination_warehouse_id)
                                                      if dest_warehouse.counter_type.blank? || dest_warehouse.counter_type.eql?("Bazar")
                                                      elsif dest_warehouse.counter_type.eql?("Bags")
                                                        if !product.goods_type_name.strip.downcase.eql?("bag") && !product.goods_type_name.strip.downcase.eql?("bags")
                                                          errors.add(:base, "Article #{product.code} is not allowed for warehouse #{dest_warehouse.code}")
                                                          break
                                                        end
                                                      elsif !dest_warehouse.counter_type.downcase.eql?(product.sex.downcase)
                                                        errors.add(:base, "Article #{product.code} is not allowed for warehouse #{dest_warehouse.code}")
                                                        break
                                                      end
                                                    end    
                                                  end    
                                                end
                                              end

                                              def delete_stock_movement(product_id, color_id, size_id, warehouse_id, transaction_date, quantity)
                                                created_movement = StockMovementTransaction.joins(stock_movement_product_detail: [stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND transaction_date = ? AND stock_transfer_quantity_received = ?", product_id, color_id, size_id, warehouse_id, transaction_date, quantity]).select(:id, :stock_movement_product_detail_id).first
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

                                              def change_listing_stock_transaction_date
                                                if received_date != received_date_was
                                                  warehouse_id = destination_warehouse_id
                                                  stock_mutation_products.select(:id, :product_id).each do |stock_mutation_product|
                                                    stock_mutation_product.stock_mutation_product_items.select(:id, :quantity, :size_id, :color_id).each do |stock_mutation_product_item|
                                                      if stock_mutation_product_item.quantity > 0
                                                        listing_stock_transaction = ListingStockTransaction.joins(listing_stock_product_detail: :listing_stock).select(:id, :transaction_date).where(["transaction_date = ? AND transaction_number = ? AND transaction_type = ? AND transactionable_id = ? AND transactionable_type = ? AND listing_stocks.warehouse_id = ?", received_date_was, number, "RGI", stock_mutation_product_item.id, stock_mutation_product_item.class.name, warehouse_id]).first
                                                        listing_stock_transaction.with_lock do
                                                          listing_stock_transaction.transaction_date = received_date
                                                          listing_stock_transaction.save
                                                        end
                                                        delete_stock_movement(stock_mutation_product.product_id, stock_mutation_product_item.color_id, stock_mutation_product_item.size_id, warehouse_id, received_date_was, stock_mutation_product_item.quantity)
                                                        create_stock_movement(stock_mutation_product.product_id, stock_mutation_product_item.color_id, stock_mutation_product_item.size_id, warehouse_id, received_date, stock_mutation_product_item.quantity, "receiving stock transfer")
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
                                                  errors.add(:base, "Sorry, inventory #{number} is not received yet")
                                                end
                                              end

                                              def new_received_date_valid
                                                errors.add(:base, "Receive date must be before or equal to #{received_date_was.strftime("%d/%m/%Y")}") if received_date_was.present? && received_date > received_date_was
                                              end

                                              def delete_old_products
                                                stock_mutation_products.select(:id).destroy_all
                                              end

                                              def create_listing_stock(product_id, color_id, size_id, warehouse_id, transaction_date, stock_mutation_product_item, mutation_type="RW")
                                                listing_stock = ListingStock.select(:id).where(warehouse_id: warehouse_id, product_id: product_id).first
                                                listing_stock = ListingStock.new warehouse_id: warehouse_id, product_id: product_id if listing_stock.blank?
                                                if listing_stock.new_record?
                                                  listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id
                                                  listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: number, transaction_type: mutation_type, transactionable_id: stock_mutation_product_item.id, transactionable_type: stock_mutation_product_item.class.name, quantity: stock_mutation_product_item.quantity
                                                  listing_stock.save
                                                else
                                                  listing_stock_product_detail = listing_stock.listing_stock_product_details.where(color_id: color_id, size_id: size_id).select(:id).first
                                                  listing_stock_product_detail = listing_stock.listing_stock_product_details.build color_id: color_id, size_id: size_id if listing_stock_product_detail.blank?
                                                  if listing_stock_product_detail.new_record?
                                                    listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: number, transaction_type: mutation_type, transactionable_id: stock_mutation_product_item.id, transactionable_type: stock_mutation_product_item.class.name, quantity: stock_mutation_product_item.quantity
                                                    listing_stock_product_detail.save
                                                  else
                                                    listing_stock_transaction = listing_stock_product_detail.listing_stock_transactions.build transaction_date: transaction_date, transaction_number: number, transaction_type: mutation_type, transactionable_id: stock_mutation_product_item.id, transactionable_type: stock_mutation_product_item.class.name, quantity: stock_mutation_product_item.quantity
                                                    listing_stock_transaction.save
                                                  end
                                                end
                                              end

                                              def create_stock_movement(product_id, color_id, size_id, warehouse_id, transaction_date, quantity, transaction_type = "return to warehouse")
                                                next_month_movements = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:id, :beginning_stock, :ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date >= ?", warehouse_id, product_id, color_id, size_id, transaction_date.next_month.beginning_of_month]).group(:id, :beginning_stock, :ending_stock)
                                                next_month_movements.each do |next_month_movement|
                                                  next_month_movement.with_lock do
                                                    if transaction_type.eql?("return to warehouse") || transaction_type.eql?("receiving stock transfer")
                                                      next_month_movement.beginning_stock += quantity
                                                      next_month_movement.ending_stock += quantity
                                                    elsif transaction_type.eql?("stock transfer")
                                                      next_month_movement.beginning_stock -= quantity
                                                      next_month_movement.ending_stock -= quantity
                                                    end
                                                    next_month_movement.save
                                                  end
                                                end

                                                stock_movement = StockMovement.select(:id).where(year: transaction_date.year).first
                                                stock_movement = StockMovement.new year: transaction_date.year if stock_movement.blank?
                                                if stock_movement.new_record?
                                                  stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month
                                                  stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                                                  stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                                                  if transaction_type.eql?("stock transfer")
                                                    beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                    beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                    if beginning_stock.nil? || beginning_stock < 1
                                                      throw :abort
                                                    end
                                                    stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                      size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                    stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_delivered: quantity, transaction_date: transaction_date
                                                  else
                                                    beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                    beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                    beginning_stock = 0 if beginning_stock.nil?
                                                    stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                      size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
                                                    if transaction_type.eql?("receiving stock transfer")
                                                      stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_received: quantity, transaction_date: transaction_date
                                                    else
                                                      stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_received: quantity, transaction_date: transaction_date
                                                    end
                                                  end
                                                  stock_movement.save
                                                else
                                                  stock_movement_month = stock_movement.stock_movement_months.select(:id).where(month: transaction_date.month).first
                                                  stock_movement_month = stock_movement.stock_movement_months.build month: transaction_date.month if stock_movement_month.blank?
                                                  if stock_movement_month.new_record?
                                                    stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                                                    stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                                                    if transaction_type.eql?("stock transfer")
                                                      beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                      beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                      if beginning_stock.nil? || beginning_stock < 1
                                                        throw :abort
                                                      end
                                                      stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                        size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                      stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_delivered: quantity, transaction_date: transaction_date
                                                    else
                                                      beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                      beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                      beginning_stock = 0 if beginning_stock.nil?
                                                      stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                        size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
                                                      if transaction_type.eql?("receiving stock transfer")
                                                        stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_received: quantity, transaction_date: transaction_date
                                                      else
                                                        stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_received: quantity, transaction_date: transaction_date
                                                      end
                                                    end
                                                    stock_movement_month.save
                                                  else
                                                    stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select(:id).where(warehouse_id: warehouse_id).first
                                                    stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
                                                    if stock_movement_warehouse.new_record?
                                                      stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                                                      if transaction_type.eql?("stock transfer")
                                                        beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                        beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                        if beginning_stock.nil? || beginning_stock < 1
                                                          throw :abort
                                                        end
                                                        stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                          size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                        stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_delivered: quantity, transaction_date: transaction_date
                                                      else
                                                        beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                        beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                        beginning_stock = 0 if beginning_stock.nil?
                                                        stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                          size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
                                                        if transaction_type.eql?("receiving stock transfer")
                                                          stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_received: quantity, transaction_date: transaction_date
                                                        else
                                                          stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_received: quantity, transaction_date: transaction_date
                                                        end
                                                      end
                                                      stock_movement_warehouse.save
                                                    else
                                                      stock_movement_product = stock_movement_warehouse.stock_movement_products.select(:id).where(product_id: product_id).first
                                                      stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
                                                      if stock_movement_product.new_record?
                                                        if transaction_type.eql?("stock transfer")
                                                          beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                          beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                          if beginning_stock.nil? || beginning_stock < 1
                                                            throw :abort
                                                          end
                                                          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                            size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                          stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_delivered: quantity, transaction_date: transaction_date
                                                        else
                                                          beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                          beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                          beginning_stock = 0 if beginning_stock.nil?
                                                          stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                            size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
                                                          if transaction_type.eql?("receiving stock transfer")
                                                            stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_received: quantity, transaction_date: transaction_date
                                                          else
                                                            stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_received: quantity, transaction_date: transaction_date
                                                          end
                                                        end
                                                        stock_movement_product.save
                                                      else
                                                        stock_movement_product_detail = stock_movement_product.stock_movement_product_details.select(:id, :ending_stock).
                                                          where(color_id: color_id, size_id: size_id).first
                                                        if stock_movement_product_detail.blank?
                                                          if transaction_type.eql?("stock transfer")
                                                            beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                            beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                            if beginning_stock.nil? || beginning_stock < 1
                                                              throw :abort
                                                            end
                                                            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                              size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                                                            stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_delivered: quantity, transaction_date: transaction_date
                                                          else
                                                            beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", warehouse_id, product_id, color_id, size_id, transaction_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                                                            beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", transaction_date.year, transaction_date.month, transaction_date.year, warehouse_id, product_id, color_id, size_id]).first.quantity rescue nil if beginning_stock.nil?
                                                            beginning_stock = 0 if beginning_stock.nil?
                                                            stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                                                              size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock + quantity)
                                                            if transaction_type.eql?("receiving stock transfer")
                                                              stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_received: quantity, transaction_date: transaction_date
                                                            else
                                                              stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_received: quantity, transaction_date: transaction_date
                                                            end
                                                          end
                                                          stock_movement_product_detail.save
                                                        else
                                                          stock_movement_product_detail.with_lock do
                                                            if transaction_type.eql?("stock transfer")
                                                              stock_movement_product_detail.ending_stock -= quantity
                                                              stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_delivered: quantity, transaction_date: transaction_date
                                                            elsif transaction_type.eql?("receiving stock transfer")
                                                              stock_movement_product_detail.ending_stock += quantity
                                                              stock_movement_product_detail.stock_movement_transactions.build stock_transfer_quantity_received: quantity, transaction_date: transaction_date
                                                            else
                                                              stock_movement_product_detail.ending_stock += quantity
                                                              stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_received: quantity, transaction_date: transaction_date
                                                            end
                                                            stock_movement_product_detail.save
                                                          end
                                                        end
                                                      end
                                                    end
                                                  end
                                                end
                                              end

                                              def transaction_open
                                                if receiving_inventory_to_store || receiving_inventory_to_warehouse || attr_change_receive_date
                                                  errors.add(:base, "Sorry, you can't perform this transaction") if FiscalYear.joins(:fiscal_months).where(year: received_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[received_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                                                elsif approving_mutation
                                                  errors.add(:base, "Sorry, you can't perform this transaction") if approved_date.present? && FiscalYear.joins(:fiscal_months).where(year: approved_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[approved_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                                                else
                                                  if FiscalYear.joins(:fiscal_months).where(year: delivery_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[delivery_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                                                    errors.add(:base, "Sorry, you can't perform this transaction")
                                                    throw :abort
                                                  end
                                                end
                                              end

                                              def load_goods_to_destination_warehouse
                                                stock = Stock.select(:id).where(warehouse_id: destination_warehouse_id).first
                                                stock = Stock.new warehouse_id: destination_warehouse_id if stock.blank?
                                                if stock.new_record?
                                                  stock_mutation_products.select(:id, :product_id).each do |stock_mutation_product|
                                                    product_id = stock_mutation_product.product_id
                                                    stock_product = stock.stock_products.build product_id: product_id
                                                    stock_mutation_product.stock_mutation_product_items.select(:id, :size_id, :color_id, :quantity).each do |stock_mutation_product_item|
                                                      if stock_mutation_product_item.quantity > 0
                                                        size_id = stock_mutation_product_item.size_id
                                                        color_id = stock_mutation_product_item.color_id
                                                        stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: stock_mutation_product_item.quantity
                                                        if receiving_inventory_to_store
                                                          create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item.quantity, "receiving stock transfer")
                                                          create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item, "RGI")
                                                        else
                                                          create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item.quantity)
                                                          create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item)
                                                        end
                                                      end
                                                    end
                                                  end
                                                  stock.save
                                                else
                                                  stock_mutation_products.select(:id, :product_id).each do |stock_mutation_product|
                                                    product_id = stock_mutation_product.product_id
                                                    stock_product = stock.stock_products.select{|stock_product| stock_product.product_id == product_id}.first
                                                    stock_product = stock.stock_products.build product_id: product_id if stock_product.blank?
                                                    if stock_product.new_record?
                                                      stock_mutation_product.stock_mutation_product_items.select(:id, :size_id, :color_id, :quantity).each do |stock_mutation_product_item|
                                                        if stock_mutation_product_item.quantity > 0
                                                          size_id = stock_mutation_product_item.size_id
                                                          color_id = stock_mutation_product_item.color_id
                                                          stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: stock_mutation_product_item.quantity
                                                          if receiving_inventory_to_store
                                                            create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item.quantity, "receiving stock transfer")
                                                            create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item, "RGI")
                                                          else
                                                            create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item.quantity)
                                                            create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item)
                                                          end
                                                        end
                                                      end
                                                      stock_product.save
                                                    else
                                                      stock_mutation_product.stock_mutation_product_items.select(:id, :size_id, :color_id, :quantity).each do |stock_mutation_product_item|
                                                        if stock_mutation_product_item.quantity > 0
                                                          size_id = stock_mutation_product_item.size_id
                                                          color_id = stock_mutation_product_item.color_id
                                                          stock_detail = stock_product.stock_details.select{|stock_detail| stock_detail.size_id == size_id && stock_detail.color_id == color_id}.first
                                                          stock_detail = stock_product.stock_details.build size_id: size_id, color_id: color_id, quantity: stock_mutation_product_item.quantity if stock_detail.blank?
                                                          if stock_detail.new_record?
                                                            if receiving_inventory_to_store
                                                              create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item.quantity, "receiving stock transfer")
                                                              create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item, "RGI")
                                                            else
                                                              create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item.quantity)
                                                              create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item)
                                                            end
                                                            stock_detail.save
                                                          else
                                                            stock_detail.with_lock do
                                                              stock_detail.quantity += stock_mutation_product_item.quantity
                                                              stock_detail.save
                                                            end
                                                            if receiving_inventory_to_store
                                                              create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item.quantity, "receiving stock transfer")
                                                              create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item, "RGI")
                                                            else
                                                              create_stock_movement(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item.quantity)
                                                              create_listing_stock(product_id, color_id, size_id, destination_warehouse_id, received_date, stock_mutation_product_item)
                                                            end
                                                          end
                                                        end
                                                      end
                                                    end
                                                  end
                                                end
                                              end

                                              def shipment_receivable
                                                errors.add(:base, "Sorry, inventory #{number} is already received") if received_date_was.present?
                                              end

                                              def update_stock
                                                raise_error = false
                                                stock_mutation_products.select(:id, :product_id).each do |stock_mutation_product|
                                                  stock_mutation_product.stock_mutation_product_items.select(:id, :quantity, :size_id, :color_id).each do |stock_mutation_product_item|
                                                    stock = StockDetail.joins(stock_product: :stock).
                                                      where(["warehouse_id = ? AND size_id = ? AND color_id = ? AND stock_products.product_id = ?", origin_warehouse_id, stock_mutation_product_item.size_id, stock_mutation_product_item.color_id, stock_mutation_product.product_id]).
                                                      select(:id, :quantity).first
                                                    stock.with_lock do
                                                      if stock_mutation_product_item.quantity > stock.quantity
                                                        raise_error = true
                                                      else
                                                        stock.quantity -= stock_mutation_product_item.quantity
                                                        stock.save
                                                      end
                                                    end
                                                    if raise_error
                                                      raise "Return quantity must be less than or equal to quantity on hand."
                                                    else
                                                      create_stock_movement(stock_mutation_product.product_id, stock_mutation_product_item.color_id, stock_mutation_product_item.size_id, origin_warehouse_id, approved_date, stock_mutation_product_item.quantity, "stock transfer")
                                                      create_listing_stock(stock_mutation_product.product_id, stock_mutation_product_item.color_id, stock_mutation_product_item.size_id, origin_warehouse_id, approved_date, stock_mutation_product_item, "RGO")
                                                    end
                                                  end
                                                end
                                              end

                                              def approvable
                                                if approved_date_was.present?
                                                  errors.add(:base, "Sorry, stock mutation #{number} is already approved")
                                                elsif destination_warehouse.warehouse_type.eql?("central")
                                                  errors.add(:base, "Sorry, stock mutation #{number} is not approvable")
                                                end
                                              end

                                              def prevent_delete_if_mutation_approved
                                                if approved_date.present? || received_date.present?
                                                  errors.add(:base, "Sorry, stock mutation #{number} cannot be deleted")
                                                  throw :abort
                                                end
                                              end

                                              def editable
                                                errors.add(:base, "The record cannot be edited") if approved_date.present? || received_date.present?
                                              end

                                              def apologize_to_previous_destination_store
                                                notification = Notification.new(event: "New Notification", body: "Sorry, stock mutation #{number} has been cancelled", user_id: audits.where(action: "update").select(:user_id, :user_type).first.user.id)
                                                destination_warehouse = Warehouse.where(id: destination_warehouse_id_was).select(:id).first
                                                destination_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
                                                  notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
                                                end
                                                notification.save
                                              end

                                              def notify_origin_store
                                                notification = Notification.new(event: "New Notification", body: "Please send #{destination_warehouse.name} a stock mutation #{number}", user_id: audits.where(action: "create").select(:user_id, :user_type).first.user.id)
                                                origin_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
                                                  notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
                                                end
                                                notification.save
                                              end

                                              def notify_destination_store
                                                notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "create").select(:user_id, :user_type).first.user.id)
                                                destination_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
                                                  notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
                                                end
                                                notification.save
                                              end

                                              def notify_new_destination_store
                                                notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "update").select(:user_id, :user_type).first.user.id)
                                                destination_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
                                                  notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
                                                end
                                                notification.save
                                              end

                                              def notify_warehouse
                                                notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "create").select(:user_id, :user_type).first.user.id)
                                                User.joins(:roles).where("roles.name = 'staff' OR roles.name = 'manager' OR roles.name = 'accountant'").select(:id).each do |user|
                                                  notification.recipients.build user_id: user.id, notified: false, read: false
                                                end
                                                notification.save
                                              end

                                              def notify_new_warehouse
                                                notification = Notification.new(event: "New Notification", body: "Stock Mutation #{number} will arrive soon", user_id: audits.where(action: "update").select(:user_id, :user_type).first.user.id)
                                                User.joins(:roles).where("roles.name = 'staff' OR roles.name = 'manager' OR roles.name = 'accountant'").select(:id).each do |user|
                                                  notification.recipients.build user_id: user.id, notified: false, read: false
                                                end
                                                notification.save
                                              end

                                              def delete_tracks
                                                audits.destroy_all
                                              end

                                              def courier_available
                                                errors.add(:courier_id, "does not exist!") if courier_id.present? && Courier.where(id: courier_id).select("1 AS one").blank?
                                              end

                                              def origin_warehouse_available
                                                errors.add(:origin_warehouse_id, "does not exist!") if (origin_warehouse_id.present? && Warehouse.not_central.not_in_transit.where(id: origin_warehouse_id).select("1 AS one").blank?) || (origin_warehouse_id.present? && destination_warehouse_id.present? && origin_warehouse_id == destination_warehouse_id)
                                              end

                                              def destination_warehouse_available
                                                if (!mutation_type.eql?("store to warehouse") && destination_warehouse_id.present? && (@dw = Warehouse.not_central.not_in_transit.where(id: destination_warehouse_id).select(:code, :counter_type).first).blank?) || (origin_warehouse_id.present? && destination_warehouse_id.present? && origin_warehouse_id == destination_warehouse_id)
                                                  errors.add(:destination_warehouse_id, "does not exist!")
                                                elsif (mutation_type.eql?("store to warehouse") && destination_warehouse_id.present? && Warehouse.central.where(id: destination_warehouse_id).select("1 AS one").blank?) || (origin_warehouse_id.present? && destination_warehouse_id.present? && origin_warehouse_id == destination_warehouse_id)
                                                  errors.add(:destination_warehouse_id, "does not exist!")
                                                end
                                              end

                                              def generate_number
                                                number_id = if mutation_type.eql?("store to warehouse")
                                                  "RW"
                                                else
                                                  "RGO"
                                                end

                                                full_warehouse_code = Warehouse.select(:code).where(id: origin_warehouse_id).first.code
                                                warehouse_code = full_warehouse_code.split("-")[0]
                                                today = Date.current
                                                current_month = today.month.to_s.rjust(2, '0')
                                                current_year = today.strftime("%y").rjust(2, '0')
                                                existed_numbers = StockMutation.where("number LIKE '#{warehouse_code}#{number_id}#{current_month}#{current_year}%'").select(:number).order(:number)
                                                if existed_numbers.blank?
                                                  new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}0001"
                                                else
                                                  if existed_numbers.length == 1
                                                    seq_number = existed_numbers[0].number.split("#{warehouse_code}#{number_id}#{current_month}#{current_year}").last
                                                    if seq_number.to_i > 1
                                                      new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}0001"
                                                    else
                                                      new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}#{seq_number.succ}"
                                                    end
                                                  else
                                                    last_seq_number = ""
                                                    existed_numbers.each_with_index do |existed_number, index|
                                                      seq_number = existed_number.number.split("#{warehouse_code}#{number_id}#{current_month}#{current_year}").last
                                                      if seq_number.to_i > 1 && index == 0
                                                        new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}0001"
                                                        break
                                                      elsif last_seq_number.eql?("")
                                                        last_seq_number = seq_number
                                                      elsif (seq_number.to_i - last_seq_number.to_i) > 1
                                                        new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}#{last_seq_number.succ}"
                                                        break
                                                      elsif index == existed_numbers.length - 1
                                                        new_number = "#{warehouse_code}#{number_id}#{current_month}#{current_year}#{seq_number.succ}"
                                                      else
                                                        last_seq_number = seq_number
                                                      end
                                                    end
                                                  end
                                                end

                                                self.number = new_number
                                              end
                                            end
