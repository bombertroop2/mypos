class StockMovementWarehouse < ApplicationRecord
  belongs_to :stock_movement_month
  belongs_to :warehouse
  has_many :stock_movement_products, dependent: :destroy
  has_many :stock_movement_product_details, through: :stock_movement_products
end
