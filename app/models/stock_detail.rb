class StockDetail < ApplicationRecord
  belongs_to :stock_product
  belongs_to :size
  belongs_to :color
end
