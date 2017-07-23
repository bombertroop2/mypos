class StockMovement < ApplicationRecord
  has_many :stock_movement_months, dependent: :destroy
end
