class ProductBarcode < ApplicationRecord
  belongs_to :product_color
  belongs_to :size

  validates :size_id, :barcode, presence: true
end
