class AllocatedReturnItem < ApplicationRecord
  belongs_to :account_payable
  belongs_to :purchase_return
  
  attr_accessor :vendor_id
  
  validate :return_item_is_valid
  
  after_create :mark_pr_as_allocated
  after_destroy :mark_pr_as_unallocated
  
  private
  
  def return_item_is_valid
    pr = PurchaseReturn.select(:id).joins(purchase_order: :vendor).where(["is_allocated = ? AND vendor_id = ? AND purchase_returns.id = ?", false, vendor_id, purchase_return_id]).first
    errors.add(:base, "Not able to allocate return item #{purchase_return.number}") unless pr
  end
  
  def mark_pr_as_allocated
    purchase_return.update_attribute(:is_allocated, true)
  end

  def mark_pr_as_unallocated
    purchase_return.update_attribute(:is_allocated, false)
  end
end