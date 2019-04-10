class StockMovementTransaction < ApplicationRecord
  belongs_to :stock_movement_product_detail
  has_many :product_details, through: :stock_movement_product_detail
end
