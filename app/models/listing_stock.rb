class ListingStock < ApplicationRecord
  belongs_to :warehouse
  belongs_to :product
  has_many :listing_stock_product_details, dependent: :destroy
end
