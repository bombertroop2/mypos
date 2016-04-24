class CostList < ActiveRecord::Base
  belongs_to :product
  
  has_many :purchase_order_products
end
