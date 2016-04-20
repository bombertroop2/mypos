class DirectPurchaseProduct < ActiveRecord::Base
  belongs_to :direct_purchase
  belongs_to :product
end
