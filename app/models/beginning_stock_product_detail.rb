class BeginningStockProductDetail < ApplicationRecord
  belongs_to :beginning_stock_product
  belongs_to :color
  belongs_to :size
end
