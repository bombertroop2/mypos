class PurchaseReturnProduct < ApplicationRecord
  attr_accessor :product_cost, :product_code, :product_name, :product_id
  
  belongs_to :purchase_order_product
  belongs_to :purchase_return
  belongs_to :direct_purchase_product
  
  has_many :purchase_return_items, dependent: :destroy
  
  accepts_nested_attributes_for :purchase_return_items, reject_if: proc {|attributes| attributes[:quantity].blank?}
  
  before_create :update_total_quantity
  
  def return_total_cost(is_it_direct_purchase)
    unless is_it_direct_purchase
      total_quantity * purchase_order_product.cost_list.cost
    else
      total_quantity * direct_purchase_product.cost_list.cost
    end
  end
  
  private
  
  def update_total_quantity
    self.total_quantity = purchase_return_items.map(&:quantity).sum
  end
  
end
