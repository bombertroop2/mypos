class ReceivedPurchaseOrderProduct < ApplicationRecord
  belongs_to :received_purchase_order
  belongs_to :purchase_order_product
  belongs_to :direct_purchase_product
  
  has_many :received_purchase_order_items, dependent: :destroy
  
  accepts_nested_attributes_for :received_purchase_order_items, reject_if: proc { |attributes| attributes[:quantity].blank? }
  
  validates :purchase_order_product_id, presence: true, if: proc{|rpop| rpop.direct_purchase_product_id.blank?}
  
    
  end
