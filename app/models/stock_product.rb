class StockProduct < ActiveRecord::Base
  belongs_to :stock
  belongs_to :product
  
  has_many :stock_details, dependent: :destroy
end
