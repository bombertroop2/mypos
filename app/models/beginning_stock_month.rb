class BeginningStockMonth < ApplicationRecord
  belongs_to :beginning_stock
  has_many :beginning_stock_products, dependent: :destroy
end
