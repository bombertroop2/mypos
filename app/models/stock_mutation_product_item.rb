class StockMutationProductItem < ApplicationRecord
  attr_accessor :product_id, :origin_warehouse_id
  
  belongs_to :stock_mutation_product
  belongs_to :size
  belongs_to :color

  validates :size_id, :color_id, :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |dpd| dpd.quantity.present? }

    validate :item_available
    validate :quantity_valid
  
    private
  
    def item_available
      @stock = StockDetail.joins(stock_product: :stock).
        where(["warehouse_id = ? AND size_id = ? AND color_id = ? AND stock_products.product_id = ?", origin_warehouse_id, size_id, color_id, product_id]).
        select(:quantity).first
      errors.add(:base, "Some products do not exist!") if @stock.blank?
    end
  
    def quantity_valid
      errors.add(:quantity, "cannot be greater than #{@stock.quantity}") if quantity > @stock.quantity
    end
  end
