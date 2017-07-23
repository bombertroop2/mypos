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
                #                before_create :create_stock_movement
      
                attr_accessor :is_it_direct_purchasing, :purchase_order_product_id,
                  :purchase_order_id, :receiving_date, :warehouse_id, :product_id
    
                private
                
                def create_stock_movement
                  last_movement = StockMovementProductDetail.joins(stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]).where("stock_movement_products.product_id = #{product_id} AND stock_movement_product_details.color_id = #{purchase_order_detail.color_id} AND stock_movement_product_details.size_id = #{purchase_order_detail.size_id} AND stock_movement_warehouses.warehouse_id = #{warehouse_id}").order("created_at DESC").select(:ending_stock).first
                  ending_stock = (last_movement.ending_stock rescue 0) + quantity
                  stock_movement = StockMovement.new year: receiving_date.year
                  stock_movement_month = stock_movement.stock_movement_months.build month: receiving_date.month
                  stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                  stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                  stock_movement_product_detail = stock_movement_product.
                    stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                    size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                    purchase_return_quantity_returned: 0, delivery_order_quantity_received: 0, delivery_order_quantity_delivered: 0,
                    stock_return_quantity_returned: 0, stock_transfer_quantity_received: 0, stock_transfer_quantity_delivered: 0,
                    ending_stock: ending_stock
                  begin
                    stock_movement.save
                  rescue ActiveRecord::RecordNotUnique => e
                    stock_movement = StockMovement.where(year: receiving_date.year).select(:id).first
                    stock_movement_month = stock_movement.stock_movement_months.build month: receiving_date.month
                    stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                    stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                    last_movement = StockMovementProductDetail.joins(stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]).where("stock_movement_products.product_id = #{product_id} AND stock_movement_product_details.color_id = #{purchase_order_detail.color_id} AND stock_movement_product_details.size_id = #{purchase_order_detail.size_id} AND stock_movement_warehouses.warehouse_id = #{warehouse_id}").order("created_at DESC").select(:ending_stock).first
                    ending_stock = (last_movement.ending_stock rescue 0) + quantity
                    stock_movement_product_detail = stock_movement_product.
                      stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                      size_id: purchase_order_detail.size_id, beginning_stock: (last_movement.ending_stock rescue 0), purchase_order_quantity_received: quantity,
                      purchase_return_quantity_returned: 0, delivery_order_quantity_received: 0, delivery_order_quantity_delivered: 0,
                      stock_return_quantity_returned: 0, stock_transfer_quantity_received: 0, stock_transfer_quantity_delivered: 0,
                      ending_stock: ending_stock
                    begin
                      stock_movement_month.save
                    rescue ActiveRecord::RecordNotUnique => e
                      stock_movement_month = stock_movement.stock_movement_months.select{|stock_movement_month| stock_movement_month.month == receiving_date.month}.first
                      stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: warehouse_id
                      stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                      stock_movement_product_detail = stock_movement_product.
                        stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                        size_id: purchase_order_detail.size_id
                      begin
                        stock_movement_warehouse.save
                      rescue ActiveRecord::RecordNotUnique => e
                        stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select{|stock_movement_warehouse| stock_movement_warehouse.warehouse_id == warehouse_id}.first
                        stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: product_id
                        stock_movement_product_detail = stock_movement_product.
                          stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                          size_id: purchase_order_detail.size_id
                        begin
                          stock_movement_product.save
                        rescue ActiveRecord::RecordNotUnique => e
                          stock_movement_product = stock_movement_warehouse.stock_movement_products.select{|stock_movement_product| stock_movement_product.product_id == product_id}.first
                          stock_movement_product_detail = stock_movement_product.
                            stock_movement_product_details.build color_id: purchase_order_detail.color_id,
                            size_id: purchase_order_detail.size_id
                          begin
                            stock_movement_product_detail.save
                          rescue ActiveRecord::RecordNotUnique => e
                            stock_movement_product_detail = stock_movement_product.
                              stock_movement_product_details.select{|stock_movement_product_detail| stock_movement_product_detail.color_id == purchase_order_detail.color_id && stock_movement_product_detail.size_id == purchase_order_detail.size_id}.first
                            stock_movement_product_detail.with_lock do
                              stock_movement_product_detail.quantity += quantity
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

                  stock = Stock.new warehouse_id: warehouse_id
                  product = purchase_order_detail.purchase_order_product.product
                  stock_product = stock.stock_products.build product_id: product.id
                  stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity
                  begin
                    stock.save
                  rescue ActiveRecord::RecordNotUnique => e
                    stock = Stock.where(warehouse_id: warehouse_id).select(:id).first
                    stock_product = stock.stock_products.build product_id: product.id
                    stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity
                    begin
                      stock_product.save
                    rescue ActiveRecord::RecordNotUnique => e
                      stock_product = stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
                      stock_detail = stock_product.stock_details.build size_id: purchase_order_detail.size_id, color_id: purchase_order_detail.color_id, quantity: quantity
                      begin
                        stock_detail.save
                      rescue ActiveRecord::RecordNotUnique => e
                        stock_detail = stock_product.stock_details.select{|sd| sd.size_id.eql?(purchase_order_detail.size_id) && sd.color_id.eql?(purchase_order_detail.color_id)}.first
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
                  stock = Stock.new warehouse_id: warehouse.id
                  product = direct_purchase_product.product
                  stock_product = stock.stock_products.build product_id: product.id
                  stock_detail = stock_product.stock_details.build size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id, quantity: direct_purchase_detail.quantity
                  begin
                    stock.save
                  rescue ActiveRecord::RecordNotUnique => e
                    stock = warehouse.stock
                    stock_product = stock.stock_products.build product_id: product.id
                    stock_detail = stock_product.stock_details.build size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id, quantity: direct_purchase_detail.quantity
                    begin
                      stock_product.save
                    rescue ActiveRecord::RecordNotUnique => e
                      stock_product = stock.stock_products.select{|sp| sp.product_id.eql?(product.id)}.first
                      stock_detail = stock_product.stock_details.build size_id: direct_purchase_detail.size_id, color_id: direct_purchase_detail.color_id, quantity: direct_purchase_detail.quantity
                      begin
                        stock_detail.save
                      rescue ActiveRecord::RecordNotUnique => e
                        stock_detail = stock_product.stock_details.select{|sd| sd.size_id.eql?(direct_purchase_detail.size_id) && sd.color_id.eql?(direct_purchase_detail.color_id)}.first
                        stock_detail.with_lock do
                          stock_detail.quantity += quantity
                          stock_detail.save
                        end
                      end
                    end
                  end
                end

              end
