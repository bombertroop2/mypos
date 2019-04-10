class StockMovementProduct < ApplicationRecord
  belongs_to :product
  belongs_to :stock_movement_warehouse
  has_many :stock_movement_product_details, dependent: :destroy
  has_many :product_details, through: :product
end
