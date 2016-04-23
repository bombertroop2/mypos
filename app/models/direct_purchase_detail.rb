class DirectPurchaseDetail < ActiveRecord::Base
  belongs_to :direct_purchase_product
  belongs_to :size
  belongs_to :color
  
  has_one :received_purchase_order_item, dependent: :destroy
  
  accepts_nested_attributes_for :received_purchase_order_item
  
  validates :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |dpd| dpd.quantity.present? }
    
    before_create :create_received_purchase_order_item
    
    private
    
    def create_received_purchase_order_item
      self.attributes = self.attributes.merge(received_purchase_order_item_attributes: {
          received_purchase_order_product_id: direct_purchase_product.received_purchase_order_product.id,
          quantity: quantity,
          direct_purchase_detail_id: id,
          is_it_direct_purchasing: true
        })
    end

  end
