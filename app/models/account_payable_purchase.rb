class AccountPayablePurchase < ApplicationRecord
  attr_accessor :vendor_id, :attr_vendor_invoice_date,
    :attr_gross_amount, :attr_first_discount_money, :attr_second_discount_money,
    :attr_vat_in_money, :attr_net_amount, :attr_purchase_number
  
  belongs_to :account_payable
  belongs_to :purchase, polymorphic: true
    
  validate :purchase_is_payable, :check_invoice_status, :purchase_payable, :attr_vendor_invoice_date_valid
  
  after_destroy :remove_invoiced_mark_from_purchase_doc
  
  private
    
  def attr_vendor_invoice_date_valid
    if purchase_type.eql?("PurchaseOrder")
      latest_received_purchase = purchase.received_purchase_orders.select(:receiving_date).order("receiving_date DESC").first
    else
      latest_received_purchase = purchase.received_purchase_order
    end
    if attr_vendor_invoice_date.present? && latest_received_purchase.receiving_date > attr_vendor_invoice_date.to_date
      errors.add(:base, "Vendor invoice date must be after or equal to #{latest_received_purchase.receiving_date.strftime("%d/%m/%Y")}")
    end
  end
  
  def purchase_payable
    if purchase_type.eql?("PurchaseOrder")
      errors.add(:base, "Not able to pay selected purchases") if PurchaseOrder.select("1 AS one").joins(:vendor).where(id: purchase_id).where(["vendors.id = ? AND vendors.is_active = ?", vendor_id, true]).blank?
    else
      errors.add(:base, "Not able to pay selected purchases") if DirectPurchase.select("1 AS one").joins(:vendor).where(id: purchase_id).where(["vendors.id = ? AND vendors.is_active = ?", vendor_id, true]).blank?
    end
  end
  
  def check_invoice_status
    errors.add(:base, "Some purchases has been invoiced") if purchase.invoice_status.eql?('Invoiced') || purchase.invoice_status.eql?('Partial')
  end
  
  def remove_invoiced_mark_from_purchase_doc
    purchase.update_attribute :invoice_status, ""           
  end
  
  def purchase_is_payable
    errors.add(:base, "Some purchases are not payable") if purchase_type.eql?("PurchaseOrder") && !purchase.status.eql?('Finish') && !purchase.status.eql?('Closed')
  end
end
