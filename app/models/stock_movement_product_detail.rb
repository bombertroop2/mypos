class StockMovementProductDetail < ApplicationRecord
  belongs_to :stock_movement_product
  belongs_to :color
  belongs_to :size
  has_many :stock_movement_transactions, dependent: :destroy
end
