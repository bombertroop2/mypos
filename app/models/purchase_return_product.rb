class PurchaseReturnProduct < ActiveRecord::Base
  belongs_to :purchase_order_product
  belongs_to :purchase_return
  
  has_many :purchase_return_items, dependent: :destroy
  
  accepts_nested_attributes_for :purchase_return_items, reject_if: proc {|attributes| attributes[:quantity].blank?}
  
  before_create :update_total_quantity
  
  def return_total_cost
    total_quantity * purchase_order_product.product.cost
  end
  
  private
  
  def update_total_quantity
    self.total_quantity = purchase_return_items.map(&:quantity).sum
  end
  
end