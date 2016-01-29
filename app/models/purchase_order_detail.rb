class PurchaseOrderDetail < ActiveRecord::Base
  belongs_to :product_detail
  belongs_to :purchase_order_product
end
