class StockMovementProductDetail < ApplicationRecord
  belongs_to :stock_movement_product
  belongs_to :color
  belongs_to :size
end
