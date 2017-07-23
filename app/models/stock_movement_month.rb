class StockMovementMonth < ApplicationRecord
  belongs_to :stock_movement
  has_many :stock_movement_warehouses, dependent: :destroy
end
