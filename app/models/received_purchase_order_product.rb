class ReceivedPurchaseOrderProduct < ActiveRecord::Base
  belongs_to :received_purchase_order
  belongs_to :purchase_order_product
  belongs_to :direct_purchase_product
  
  has_many :received_purchase_order_items, dependent: :destroy
  
  accepts_nested_attributes_for :received_purchase_order_items, reject_if: proc { |attributes| attributes[:quantity].blank? }
  
  
  
end
