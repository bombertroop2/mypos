class BeginningStockProduct < ApplicationRecord
  belongs_to :beginning_stock_month
  belongs_to :product
  has_many :beginning_stock_product_details, dependent: :destroy
end
