class DirectPurchaseDetail < ApplicationRecord
  attr_accessor :product_id

  belongs_to :direct_purchase_product
  belongs_to :size
  belongs_to :color
  
  has_one :received_purchase_order_item, dependent: :destroy
  
  accepts_nested_attributes_for :received_purchase_order_item
  
  validates :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |dpd| dpd.quantity.present? }
    validate :item_available, on: :create
    
    before_create :create_received_purchase_order_item, :calculate_total_unit_price
    
    private
      
    def item_available
      errors.add(:base, "Not able to receive selected items") unless Product.select("1 AS one").joins(:product_colors, :product_details).where("products.id = '#{product_id}' AND color_id = '#{color_id}' AND size_id = '#{size_id}'").present?
    end
    
    def calculate_total_unit_price
      self.total_unit_price = quantity * direct_purchase_product.cost_list.cost
    end
    
    def create_received_purchase_order_item
      self.attributes = self.attributes.merge(received_purchase_order_item_attributes: {
          received_purchase_order_product_id: direct_purchase_product.received_purchase_order_product.id,
          quantity: quantity,
          direct_purchase_detail_id: id,
          is_it_direct_purchasing: true
        })
    end

  end
