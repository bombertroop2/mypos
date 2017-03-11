class PurchaseReturn < ApplicationRecord
  has_many :purchase_return_products, dependent: :destroy
  belongs_to :purchase_order
  
  before_validation :generate_number
  
  validate :check_min_return_quantity, :purchase_order_is_returnable, if: proc {|pr| pr.purchase_order_id.present?}
  validates :purchase_order_id, presence: true
  
  accepts_nested_attributes_for :purchase_return_products
    
  private
  
  def purchase_order_is_returnable
    errors.add(:purchase_order_id, "return is not allowed") if PurchaseOrder.where(["status != 'Open' AND status != 'Deleted' AND id = ?", purchase_order_id]).select("1 AS one").blank?
  end
  
  def check_min_return_quantity
    valid = false
    purchase_return_products.each do |purchase_return_product|
      if purchase_return_product.purchase_return_items.present?
        valid = true
        break
      end
    end
    errors.add(:base, "Purchase return must have at least one return item") unless valid
  end
  
  def generate_number
    last_pr = PurchaseReturn.last
    today = Date.today
    current_month = today.month.to_s.rjust(2, '0')
    current_year = today.strftime("%y").rjust(2, '0')
    if last_pr
      seq_number = last_pr.number.split(last_pr.number.scan(/PRR\d.{3}/).first).last.succ
      new_pr_number = "#{(purchase_order.warehouse.code if purchase_order and purchase_order.warehouse)}PRR#{current_month}#{current_year}#{seq_number}"
    else
      new_pr_number = "#{(purchase_order.warehouse.code if purchase_order and purchase_order.warehouse)}PRR#{current_month}#{current_year}0001"
    end
    self.number = new_pr_number
  end

end
