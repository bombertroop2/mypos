class ListingStockProductDetail < ApplicationRecord
  belongs_to :listing_stock
  belongs_to :color
  belongs_to :size
  has_many :listing_stock_transactions, dependent: :destroy
end
