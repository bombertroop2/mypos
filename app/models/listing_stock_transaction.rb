class ListingStockTransaction < ApplicationRecord
  belongs_to :listing_stock_product_detail
  belongs_to :transactionable, polymorphic: true
end
