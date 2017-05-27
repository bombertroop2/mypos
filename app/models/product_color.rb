class ProductColor < ApplicationRecord
  belongs_to :product
  belongs_to :color
  
  attr_accessor :code, :name, :selected_color_id
  
  validates :color_id, presence: true
  validate :color_available
  
  before_destroy :prevent_deleting_if_po_is_created, :prevent_deleting_if_direct_purchase_is_created, :prevent_deleting_if_order_booking_is_created
  
  private
  
  def color_available
    errors.add(:color_id, "does not exist!") if color_id.present? && Color.where(id: color_id).select("1 AS one").blank?
  end
  
  def prevent_deleting_if_po_is_created    
    throw :abort if PurchaseOrderDetail.joins(purchase_order_product: :purchase_order).select("1 AS one").where(["color_id = ? AND purchase_order_products.product_id = ? AND purchase_orders.status <> 'Deleted'", color_id, product_id]).first.present?
  end

  def prevent_deleting_if_direct_purchase_is_created        
    throw :abort if DirectPurchaseDetail.joins(:direct_purchase_product).select("1 AS one").where(["color_id = ? AND product_id = ?", color_id, product_id]).first.present?
  end
  
  def prevent_deleting_if_order_booking_is_created
    throw :abort if OrderBookingProduct.joins(:order_booking_product_items).select("1 AS one").where(["color_id = ? AND product_id = ?", color_id, product_id]).first.present?
  end
end
