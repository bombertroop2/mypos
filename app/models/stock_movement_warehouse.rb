class StockMovementWarehouse < ApplicationRecord
  belongs_to :stock_movement_month
  belongs_to :warehouse
  has_many :stock_movement_products, dependent: :destroy
end
