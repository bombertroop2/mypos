class StockProduct < ApplicationRecord
  belongs_to :stock
  belongs_to :product
  
  has_many :stock_details, dependent: :destroy
  
  has_many :sizes, -> { group("sizes.id").order(:size_order) }, through: :stock_details
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :stock_details, source: :color

end
