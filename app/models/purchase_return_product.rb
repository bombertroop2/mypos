class PurchaseReturnProduct < ApplicationRecord
  attr_accessor :product_cost, :product_code, :product_name, :product_id, :purchase_order_id
  
  belongs_to :purchase_order_product
  belongs_to :purchase_return
  belongs_to :direct_purchase_product
  
  has_many :purchase_return_items, dependent: :destroy
  
  accepts_nested_attributes_for :purchase_return_items, reject_if: proc {|attributes| attributes[:quantity].blank?}
  
  validate :product_returnable, on: :create
  
  before_create :update_total_quantity
  
  def return_total_cost(is_it_direct_purchase)
    unless is_it_direct_purchase
      total_quantity * purchase_order_product.cost_list.cost
    else
      total_quantity * direct_purchase_product.cost_list.cost
    end
  end
  
  private
  
  def product_returnable
    errors.add(:base, "Not able to return selected products") unless PurchaseOrderProduct.select("1 AS one").joins(:purchase_order).where("purchase_order_products.id = #{purchase_order_product_id} AND purchase_orders.id = #{purchase_order_id} AND status != 'Open' AND status != 'Deleted'").present?
  end
  
  def update_total_quantity
    self.total_quantity = purchase_return_items.map(&:quantity).sum
  end
  
end
