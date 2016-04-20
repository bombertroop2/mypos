class DirectPurchaseDetail < ActiveRecord::Base
  belongs_to :direct_purchase_product
  belongs_to :size
  belongs_to :color
end
