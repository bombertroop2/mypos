class StockMovementProduct < ApplicationRecord
  belongs_to :product
  belongs_to :stock_movement_warehouse
  belongs_to :product
  has_many :stock_movement_product_details, dependent: :destroy
end
