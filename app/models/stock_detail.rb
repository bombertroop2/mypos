class StockDetail < ActiveRecord::Base
  belongs_to :stock_product
  belongs_to :size
  belongs_to :color
end
