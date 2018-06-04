class ProductBarcode < ApplicationRecord
  belongs_to :product_color
  belongs_to :size
  
  has_many :sale_products, dependent: :restrict_with_error
  has_many :consignment_sale_products, dependent: :restrict_with_error

  validates :size_id, :barcode, presence: true
end
