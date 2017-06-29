class ShipmentReceiptProduct < ApplicationRecord
  attr_accessor :shipment_id

  belongs_to :shipment_receipt
  belongs_to :shipment_product
  has_many :shipment_receipt_product_items, dependent: :destroy

  accepts_nested_attributes_for :shipment_receipt_product_items
  
  validates :shipment_product_id, presence: true
  validate :product_available, if: proc{|shpmnt_prdct| shpmnt_prdct.shipment_product_id.present?}
    
    before_create :calculate_quantity

    private
    
    def calculate_quantity
      self.quantity = shipment_product.quantity
    end

    def product_available
      errors.add(:shipment_product_id, "does not exist!") if ShipmentProduct.joins(:shipment).select("1 AS one").where(["received_date IS NULL AND shipment_products.id = ? AND shipment_id = ?", shipment_product_id, shipment_id]).blank?
    end
  end
