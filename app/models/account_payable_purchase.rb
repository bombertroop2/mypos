class AccountPayablePurchase < ApplicationRecord
  attr_accessor :vendor_id
  
  belongs_to :account_payable
  belongs_to :purchase, polymorphic: true
  
  validate :purchase_is_payable, :check_invoice_status, :purchase_payable
  
  after_destroy :remove_invoiced_mark_from_purchase_doc
  
  private
  
  def purchase_payable
    if purchase_type.eql?("PurchaseOrder")
      errors.add(:base, "Not able to pay selected purchases") if PurchaseOrder.select("1 AS one").joins(:vendor).where(id: purchase_id).where(["vendors.id = ? AND vendors.is_active = ?", vendor_id, true]).blank?
    else
      errors.add(:base, "Not able to pay selected purchases") if DirectPurchase.select("1 AS one").joins(:vendor).where(id: purchase_id).where(["vendors.id = ? AND vendors.is_active = ?", vendor_id, true]).blank?
    end
  end
  
  def check_invoice_status
    errors.add(:base, "Some purchases has been invoiced") if purchase.invoice_status.eql?('Invoiced')
  end
  
  def remove_invoiced_mark_from_purchase_doc
    purchase.update_attribute :invoice_status, ""           
  end
  
  def purchase_is_payable
    errors.add(:base, "Some purchases are not payable") if purchase_type.eql?("PurchaseOrder") && !purchase.status.eql?('Finish') && !purchase.status.eql?('Closed')
  end
end
