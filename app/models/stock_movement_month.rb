class StockMovementMonth < ApplicationRecord
  belongs_to :stock_movement
  has_many :stock_movement_warehouses, dependent: :destroy
  has_many :stock_movement_products, through: :stock_movement_warehouses
  has_many :stock_movement_product_details, through: :stock_movement_products
end
