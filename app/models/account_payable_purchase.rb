class AccountPayablePurchase < ApplicationRecord
  attr_accessor :vendor_id
  
  belongs_to :account_payable
  belongs_to :purchase, polymorphic: true
  
  validate :purchase_is_payable, :check_payment_status, :purchase_payable
  
  after_destroy :remove_paid_mark_from_purchase_doc
  
  private
  
  def purchase_payable
    errors.add(:base, "Not able to pay selected purchases") if purchase_type.eql?("PurchaseOrder") && PurchaseOrder.select("1 AS one").joins(:vendor).where(id: purchase_id).where("vendors.id = #{vendor_id}").blank?
  end
  
  def check_payment_status
    errors.add(:base, "Some purchases has been paid") if purchase.payment_status.eql?('Paid')
  end
  
  def remove_paid_mark_from_purchase_doc
    purchase.update_attribute :payment_status, ""           
  end
  
  def purchase_is_payable
    errors.add(:base, "Some purchases are not payable") if purchase_type.eql?("PurchaseOrder") && !purchase.status.eql?('Finish') && !purchase.status.eql?('Closed')
  end
end
