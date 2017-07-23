class ReceivedPurchaseOrderItem < ApplicationRecord
  belongs_to :purchase_order_detail
  belongs_to :received_purchase_order_product
  belongs_to :direct_purchase_detail
  
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |rpoi| rpoi.quantity.present? }
    validate :less_than_or_equal_to_order, if: proc {|rpoi| rpoi.quantity.present? && rpoi.quantity > 0 && !rpoi.is_it_direct_purchasing}
      validates :purchase_order_detail_id, presence: true, if: proc{|rpoi| rpoi.direct_purchase_detail_id.blank?}
        validate :purchase_order_detail_receivable, if: proc{|rpoi| rpoi.direct_purchase_detail_id.blank?}
      
          before_create :update_receiving_value, unless: proc {|rpoi| rpoi.is_it_direct_purchasing}
            before_create :create_stock_and_update_receiving_qty, unless: proc {|rpoi| rpoi.is_it_direct_purchasing}
              before_create :create_stock, if: proc {|rpoi| rpoi.is_it_direct_purchasing}
                before_create :create_stock_movement
      
                attr_accessor :is_it_direct_purchasing, :purchase_order_product_id,
                  :purchase_order_id, :receiving_date, :warehouse_id, :product_id
    
                private
                
                def create_stock_movement
                  last_movement = unless is_it_direct_purchasing
                    StockMovementProductDetail.joins(stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND last_transaction_date <= ?", product_id, purchase_order_detail.color_id, purchase_order_detail.size_id, warehouse_id, receiving_date.to_date.prev_month.end_of_month]).order("last_transaction_date DESC, stock_movement_product_details.id DESC").select(:ending_stock).first
                  else
                    StockMovementProductDetail.joins(stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND last_transaction_date <= ?", product_id, direct_purchase_detail.color_id, direct_purchase_detail.size_id, warehouse_id, receiving_date.to_date.prev_month.end_of_month]).order("last_transaction_date DESC, stock_movement_product_details.id DESC").select(:ending_stock).first
                  end
                  ending_stock = (last_movement.ending_stock rescue 0) + quantity
                  
                  stock_movement = StockMovement.select(:id).where(year: receiving_date.to_date.year).first
                  stock_movement = StockMovement.new year: receiving_date.to_date.year if stock_movement.blank?
                  if stock_movement.new_record?                    
                    stock_movement_month = stock_movement.stock_movement_months.build month: receiving_date.to_date.month
                    stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                    stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                    stock_movement_product_detail = unless is_it_direct_purchasing
                      stock_movement_product.stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                        size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                        ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                    else
                      stock_movement_product.stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
                        size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                        ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                    end
                    stock_movement.save
                  else
                    stock_movement_month = stock_movement.stock_movement_months.select{|stock_movement_month| stock_movement_month.month == receiving_date.to_date.month}.first
                    stock_movement_month = stock_movement.stock_movement_months.build month: receiving_date.to_date.month if stock_movement_month.blank?
                    if stock_movement_month.new_record?                      
                      stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                      stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                      stock_movement_product_detail = unless is_it_direct_purchasing
                        stock_movement_product.
                          stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                          size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                          ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                      else
                        stock_movement_product.
                          stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
                          size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                          ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                      end
                      stock_movement_month.save
                    else
                      stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select{|stock_movement_warehouse| stock_movement_warehouse.warehouse_id == warehouse_id}.first
                      stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id if stock_movement_warehouse.blank?
                      if stock_movement_warehouse.new_record?                        
                        stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                        stock_movement_product_detail = unless is_it_direct_purchasing
                          stock_movement_product.
                            stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                            size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                            ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                        else
                          stock_movement_product.
                            stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
                            size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                            ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                        end
                        stock_movement_warehouse.save
                      else
                        stock_movement_product = stock_movement_warehouse.stock_movement_products.select{|stock_movement_product| stock_movement_product.product_id == product_id}.first
                        stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id if stock_movement_product.blank?
                        if stock_movement_product.new_record?                          
                          stock_movement_product_detail = unless is_it_direct_purchasing
                            stock_movement_product.
                              stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                              size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                              ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                          else
                            stock_movement_product.
                              stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
                              size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                              ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                          end
                          stock_movement_product.save
                        else
                          stock_movement_product_detail = unless is_it_direct_purchasing
                            stock_movement_product.stock_movement_product_details.
                              select{|stock_movement_product_detail| stock_movement_product_detail.color_id == purchase_order_detail.color_id && stock_movement_product_detail.size_id == purchase_order_detail.size_id}.first
                          else
                            stock_movement_product.stock_movement_product_details.
                              select{|stock_movement_product_detail| stock_movement_product_detail.color_id == direct_purchase_detail.color_id && stock_movement_product_detail.size_id == direct_purchase_detail.size_id}.first
                          end
                          if stock_movement_product_detail.blank?
                            stock_movement_product_detail = unless is_it_direct_purchasing
                              stock_movement_product.
                                stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                                size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                                ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                            else
                              stock_movement_product.
                                stock_movement_product_details.build color_id: direct_purchase_detail.color_id,
                                size_id: direct_purchase_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                                ending_stock: ending_stock, last_transaction_date: receiving_date.to_date
                            end
                            stock_movement_product_detail.save
                          else
                            stock_movement_product_detail.with_lock do
                              stock_movement_product_detail.beginning_stock = last_movement.ending_stock rescue 0
                              stock_movement_product_detail.purchase_order_quantity_received = stock_movement_product_detail.purchase_order_quantity_received.to_i + quantity
                              stock_movement_product_detail.ending_stock += quantity
                              stock_movement_product_detail.last_transaction_date = receiving_date.to_date
                              stock_movement_product_detail.save
                            end
                          end
                        end
                      end
                    end
                  end
                end
                
                def purchase_order_detail_receivable
                  errors.add(:base, "Not able to receive selected items") unless PurchaseOrderDetail.select("1 AS one").joins(purchase_order_product: :purchase_order).where("(status = 'Open' OR status = 'Partial') AND purchase_orders.id = '#{purchase_order_id}' AND purchase_order_products.id = '#{purchase_order_product_id}' AND purchase_order_details.id = '#{purchase_order_detail_id}'").present?
                end
      
      
                def update_receiving_value
                  raise_error = false
                  purchase_order = received_purchase_order_product.received_purchase_order.purchase_order
                  purchase_order.with_lock do
                    if purchase_order.receiving_value.nil? || purchase_order.receiving_value < purchase_order.order_value
                      purchase_order.receiving_po = true
                      purchase_order.receiving_value = purchase_order.receiving_value.to_f + received_purchase_order_product.purchase_order_product.cost_list.cost * quantity
                      if purchase_order.receiving_value < purchase_order.order_value
                        purchase_order.status = "Partial"
                        purchase_order.without_auditing do
                          purchase_order.save validate: false
                        end                      
                      elsif purchase_order.receiving_value == purchase_order.order_value
                        purchase_order.status = "Finish"
                        purchase_order.without_auditing do
                          purchase_order.save validate: false
                        end                      
                      else
                        raise_error = true
                      end
                    else
                      raise_error = true                      
                    end
                  end
                  
                  raise "Sorry, purchase order #{purchase_order.number} has already been finished" if raise_error
                end
    
                def less_than_or_equal_to_order
                  remains_quantity = purchase_order_detail.quantity - purchase_order_detail.receiving_qty.to_i
                  errors.add(:quantity, "must be less than or equal to remaining ordered quantity.") if quantity > remains_quantity
                end
      
                def create_stock_and_update_receiving_qty
                  raise_error = false
                  purchase_order_detail.with_lock do
                    remains_quantity = purchase_order_detail.quantity - purchase_order_detail.receiving_qty.to_i
                    if quantity <= remains_quantity
                      purchase_order_detail.is_updating_receiving_quantity = true
                      purchase_order_detail.receiving_qty = purchase_order_detail.receiving_qty.to_i + quantity
                      purchase_order_detail.save
                    else
                      raise_error = true
                    end
                  end
                  raise "Quantity must be less than or equal to remaining ordered quantity." if raise_error

                  stock = Stock.where(warehouse_id: warehouse_id).select(:id).first
                  stock = Stock.new warehouse_id: warehouse_id if stock.blank?
                  product = purchase_order_detail.purchase_order_product.product
                  if stock.new_record?
                    stock_product = stock.stock_products.build product_id: product.id
                    stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity
                    stock.save
                  else
                    stock_product = stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
                    stock_product = stock.stock_products.build product_id: product.id if stock_product.blank?
                    if stock_product.new_record?                      
                      stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity
                      stock_product.save
                    else
                      stock_detail = stock_product.stock_details.select{|stock_detail| stock_detail.size_id == purchase_order_detail.size_id && stock_detail.color_id == purchase_order_detail.color_id}.first
                      stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity if stock_detail.blank?
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
                end
      
                def create_stock
                  direct_purchase_product = direct_purchase_detail.direct_purchase_product
                  warehouse = direct_purchase_product.direct_purchase.warehouse                  
                  stock = Stock.select(:id).where(warehouse_id: warehouse.id).first
                  stock = Stock.new warehouse_id: warehouse.id if stock.blank?
                  product = direct_purchase_product.product
                  if stock.new_record?                    
                    stock_product = stock.stock_products.build product_id: product.id
                    stock_detail = stock_product.stock_details.build size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id, quantity: direct_purchase_detail.quantity
                    stock.save
                  else
                    stock_product = stock.stock_products.select{|stock_product| stock_product.product_id == product.id}.first
                    stock_product = stock.stock_products.build product_id: product.id if stock_product.blank?
                    if stock_product.new_record?                      
                      stock_detail = stock_product.stock_details.build size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id, quantity: direct_purchase_detail.quantity
                      stock_product.save
                    else
                      stock_detail = stock_product.stock_details.select{|sd| sd.size_id.eql?(direct_purchase_detail.size_id) && sd.color_id.eql?(direct_purchase_detail.color_id)}.first
                      stock_detail = stock_product.stock_details.build size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id, quantity: direct_purchase_detail.quantity
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
                end

              end
