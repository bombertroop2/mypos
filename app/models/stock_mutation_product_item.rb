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
    
    before_destroy :return_goods_to_warehouse, if: proc{|smpi| smpi.stock_mutation_product.stock_mutation.destination_warehouse.warehouse_type.eql?("central")}
      before_destroy :delete_tracks
      before_update :update_stock, if: proc{|smpi| smpi.mutation_type.eql?("store to warehouse")}
        before_create :update_stock, if: proc{|smpi| smpi.mutation_type.eql?("store to warehouse")}
  
          private
    
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
