class AllocatedReturnItem < ApplicationRecord
  belongs_to :purchase_return
  belongs_to :account_payable_payment_invoice
  
  after_create :mark_pr_as_allocated
  
  private
    
  def mark_pr_as_allocated
    purchase_return.update_attribute(:is_allocated, true)
  end
end