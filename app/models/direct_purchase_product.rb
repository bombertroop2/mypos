class DirectPurchaseProduct < ActiveRecord::Base
  belongs_to :direct_purchase
  belongs_to :product
  
  has_one :received_purchase_order_product, dependent: :destroy
  has_many :direct_purchase_details, dependent: :destroy
  
  validate :should_has_details, on: :create
  
  accepts_nested_attributes_for :received_purchase_order_product
  accepts_nested_attributes_for :direct_purchase_details, reject_if: proc { |attributes| attributes[:quantity].blank? }

  before_create :create_received_purchase_order_product

  private  
  
  def should_has_details    
    errors.add(:base, "Please insert at least one piece per product!") if direct_purchase_details.blank?
  end
  
  def create_received_purchase_order_product
    self.attributes = self.attributes.merge(received_purchase_order_product_attributes: {
        received_purchase_order_id: direct_purchase.received_purchase_order.id,
        direct_purchase_product_id: id
      })
  end
end
