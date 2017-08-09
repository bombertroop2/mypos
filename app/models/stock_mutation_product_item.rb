class StockMutationProductItem < ApplicationRecord
  attr_accessor :product_id, :origin_warehouse_id, :mutation_type
  
  audited associated_with: :stock_mutation_product, on: [:create, :update]

  belongs_to :stock_mutation_product
  belongs_to :size
  belongs_to :color

  validates :size_id, :color_id, :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |dpd| dpd.quantity.present? }

    validate :item_available
    validate :quantity_valid
    
    before_destroy :return_goods_to_warehouse, :delete_stock_movement, if: proc{|smpi| smpi.stock_mutation_product.stock_mutation.destination_warehouse.warehouse_type.eql?("central")}
      before_destroy :delete_tracks
      before_update :update_stock, if: proc{|smpi| smpi.mutation_type.eql?("store to warehouse")}
        before_create :update_stock, :create_stock_movement, if: proc{|smpi| smpi.mutation_type.eql?("store to warehouse")}
  
          private
          
          def delete_stock_movement
            stock_mutation_product = StockMutationProduct.select(:stock_mutation_id, :product_id).where(id: stock_mutation_product_id).first
            stock_mutation = StockMutation.select(:delivery_date, :origin_warehouse_id).where(id: stock_mutation_product.stock_mutation_id).first
            product_id = stock_mutation_product.product_id
            warehouse_id = stock_mutation.origin_warehouse_id            
            transaction_date = stock_mutation.delivery_date
            created_movement = StockMovementTransaction.joins(stock_movement_product_detail: [stock_movement_product: [stock_movement_warehouse: [stock_movement_month: :stock_movement]]]).where(["stock_movement_products.product_id = ? AND stock_movement_product_details.color_id = ? AND stock_movement_product_details.size_id = ? AND stock_movement_warehouses.warehouse_id = ? AND transaction_date = ? AND stock_return_quantity_returned = ?", product_id, color_id, size_id, warehouse_id, transaction_date, quantity]).select(:id, :stock_movement_product_detail_id).first
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
          
          def create_stock_movement
            stock_mutation_product = StockMutationProduct.select(:stock_mutation_id, :product_id).where(id: stock_mutation_product_id).first
            stock_mutation = StockMutation.select(:delivery_date, :origin_warehouse_id).where(id: stock_mutation_product.stock_mutation_id).first
            stock_movement = StockMovement.select(:id).where(year: stock_mutation.delivery_date.year).first
            stock_movement = StockMovement.new year: stock_mutation.delivery_date.year if stock_movement.blank?
            if stock_movement.new_record?                    
              stock_movement_month = stock_movement.stock_movement_months.build month: stock_mutation.delivery_date.month
              stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: stock_mutation.origin_warehouse_id
              stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: stock_mutation_product.product_id
              beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id, stock_mutation.delivery_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
              beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", stock_mutation.delivery_date.year, stock_mutation.delivery_date.month, stock_mutation.delivery_date.year, stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
              if beginning_stock < 1
                throw :abort
              end
              stock_movement_product_detail = stock_movement_product.stock_movement_product_details.build color_id: color_id,
                size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
              stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_returned: quantity, transaction_date: stock_mutation.delivery_date
              stock_movement.save
            else
              stock_movement_month = stock_movement.stock_movement_months.select{|stock_movement_month| stock_movement_month.month == stock_mutation.delivery_date.month}.first
              stock_movement_month = stock_movement.stock_movement_months.build month: stock_mutation.delivery_date.month if stock_movement_month.blank?
              if stock_movement_month.new_record?                      
                stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: stock_mutation.origin_warehouse_id
                stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: stock_mutation_product.product_id
                beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id, stock_mutation.delivery_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", stock_mutation.delivery_date.year, stock_mutation.delivery_date.month, stock_mutation.delivery_date.year, stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
                if beginning_stock < 1
                  throw :abort
                end
                stock_movement_product_detail = stock_movement_product.
                  stock_movement_product_details.build color_id: color_id,
                  size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_returned: quantity, transaction_date: stock_mutation.delivery_date
                stock_movement_month.save
              else
                stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.select{|stock_movement_warehouse| stock_movement_warehouse.warehouse_id == stock_mutation.origin_warehouse_id}.first
                stock_movement_warehouse = stock_movement_month.stock_movement_warehouses.build warehouse_id: stock_mutation.origin_warehouse_id if stock_movement_warehouse.blank?
                if stock_movement_warehouse.new_record?                        
                  stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: stock_mutation_product.product_id
                  beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id, stock_mutation.delivery_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                  beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", stock_mutation.delivery_date.year, stock_mutation.delivery_date.month, stock_mutation.delivery_date.year, stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
                  if beginning_stock < 1
                    throw :abort
                  end
                  stock_movement_product_detail = stock_movement_product.
                    stock_movement_product_details.build color_id: color_id,
                    size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                  stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_returned: quantity, transaction_date: stock_mutation.delivery_date
                  stock_movement_warehouse.save
                else
                  stock_movement_product = stock_movement_warehouse.stock_movement_products.select{|stock_movement_product| stock_movement_product.product_id == stock_mutation_product.product_id}.first
                  stock_movement_product = stock_movement_warehouse.stock_movement_products.build product_id: stock_mutation_product.product_id if stock_movement_product.blank?
                  if stock_movement_product.new_record?                          
                    beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id, stock_mutation.delivery_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                    beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", stock_mutation.delivery_date.year, stock_mutation.delivery_date.month, stock_mutation.delivery_date.year, stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
                    if beginning_stock < 1
                      throw :abort
                    end
                    stock_movement_product_detail = stock_movement_product.
                      stock_movement_product_details.build color_id: color_id,
                      size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                    stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_returned: quantity, transaction_date: stock_mutation.delivery_date
                    stock_movement_product.save
                  else
                    stock_movement_product_detail = stock_movement_product.stock_movement_product_details.
                      select{|stock_movement_product_detail| stock_movement_product_detail.color_id == color_id && stock_movement_product_detail.size_id == size_id}.first
                    if stock_movement_product_detail.blank?
                      beginning_stock = StockMovementProductDetail.joins(:stock_movement_transactions, stock_movement_product: :stock_movement_warehouse).select(:ending_stock).where(["warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ? AND transaction_date <= ?", stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id, stock_mutation.delivery_date.prev_month.end_of_month]).order("transaction_date DESC").first.ending_stock rescue nil
                      beginning_stock = BeginningStockProductDetail.joins(beginning_stock_product: [beginning_stock_month: :beginning_stock]).select(:quantity).where(["((year = ? AND month <= ?) OR year < ?) AND warehouse_id = ? AND product_id = ? AND color_id = ? AND size_id = ?", stock_mutation.delivery_date.year, stock_mutation.delivery_date.month, stock_mutation.delivery_date.year, stock_mutation.origin_warehouse_id, stock_mutation_product.product_id, color_id, size_id]).first.quantity if beginning_stock.nil?
                      if beginning_stock < 1
                        throw :abort
                      end
                      stock_movement_product_detail = stock_movement_product.
                        stock_movement_product_details.build color_id: color_id,
                        size_id: size_id, beginning_stock: beginning_stock, ending_stock: (beginning_stock - quantity)
                      stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_returned: quantity, transaction_date: stock_mutation.delivery_date
                      stock_movement_product_detail.save
                    else
                      stock_movement_product_detail.with_lock do
                        stock_movement_product_detail.ending_stock -= quantity                      
                        stock_movement_product_detail.stock_movement_transactions.build stock_return_quantity_returned: quantity, transaction_date: stock_mutation.delivery_date
                        stock_movement_product_detail.save
                      end
                    end
                  end
                end
              end
            end
          end
    
          def delete_tracks
            audits.destroy_all
          end
  
          def item_available
            @stock = if stock_mutation_product.blank?
              StockDetail.joins(stock_product: :stock).
                where(["warehouse_id = ? AND size_id = ? AND color_id = ? AND stock_products.product_id = ?", origin_warehouse_id, size_id, color_id, product_id]).
                select(:id, :quantity).first
            else
              StockDetail.joins(stock_product: :stock).
                where(["warehouse_id = ? AND size_id = ? AND color_id = ? AND stock_products.product_id = ?", stock_mutation_product.stock_mutation.origin_warehouse_id, size_id, color_id, stock_mutation_product.product_id]).
                select(:id, :quantity).first
            end
            errors.add(:base, "Some products do not exist!") if @stock.blank?
          end
  
          def quantity_valid
            if new_record?
              errors.add(:quantity, "cannot be greater than #{@stock.quantity}") if quantity.to_i > @stock.quantity
            else
              errors.add(:quantity, "cannot be greater than #{@stock.quantity + quantity_was}") if quantity.to_i > @stock.quantity + quantity_was
            end
          end
    
          def update_stock
            raise_error = false
            if new_record?
              @stock.with_lock do
                if quantity.to_i > @stock.quantity
                  raise_error = true
                else
                  @stock.quantity -= quantity
                  @stock.save
                end
              end
            else
              @stock.with_lock do
                if quantity.to_i > @stock.quantity + quantity_was
                  raise_error = true
                else
                  @stock.quantity = @stock.quantity + quantity_was - quantity
                  @stock.save
                end
              end
            end
            raise "Return quantity must be less than or equal to quantity on hand." if raise_error
          end
      
          def return_goods_to_warehouse
            warehouse_stock = StockDetail.joins(stock_product: :stock).
              where(["warehouse_id = ? AND size_id = ? AND color_id = ? AND stock_products.product_id = ?", stock_mutation_product.stock_mutation.origin_warehouse_id, size_id, color_id, stock_mutation_product.product_id]).
              select(:id, :quantity).first
            warehouse_stock.with_lock do
              warehouse_stock.quantity += quantity
              warehouse_stock.save
            end
          end
        end
