class AccountPayablePurchase < ApplicationRecord
  belongs_to :account_payable
  belongs_to :purchase, polymorphic: true
  
  validate :purchase_is_payable, :check_payment_status
  
  after_destroy :remove_paid_mark_from_purchase_doc
  
  private
  
  def check_payment_status
    errors.add(:base, "Some purchases has been paid") if purchase.payment_status.eql?('Paid')
  end
  
  def remove_paid_mark_from_purchase_doc
    purchase.update_attribute :payment_status, ""           
  end
  
  def purchase_is_payable
    errors.add(:base, "Some purchases are not payable") if !purchase.status.eql?('Finish') && !purchase.status.eql?('Closed')
  end
end
