class ProductColor < ApplicationRecord
  belongs_to :product
  belongs_to :color
  
  attr_accessor :code, :name, :selected_color_id
  
  before_destroy :prevent_deleting_if_po_is_created
  
  private
  
  def prevent_deleting_if_po_is_created    
    throw :abort if PurchaseOrderDetail.joins(purchase_order_product: :purchase_order).select("1 AS one").where(["color_id = ? AND purchase_order_products.product_id = ? AND purchase_orders.status <> 'Deleted'", color_id, product_id]).first.present?
  end
end
