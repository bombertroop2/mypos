class AccountPayablePurchasePartial < ApplicationRecord
  attr_accessor :attr_delivery_order_number, :attr_purchase_order_number, :attr_received_quantity, :attr_gross_amount, :attr_first_discount_money, :attr_second_discount_money, :attr_is_additional_disc_from_net, :attr_vat_in_money, :attr_net_amount, :attr_receiving_date
  
  belongs_to :account_payable
  belongs_to :received_purchase_order
  has_many :received_purchase_order_products, through: :received_purchase_order
  
  after_create :mark_received_purchase_as_invoiced, :mark_purchase_document_invoice_status_as_partial
  after_destroy :remove_invoiced_mark_from_received_purchase, :remove_partial_mark_from_purchase_document
  
  private
  
  def remove_partial_mark_from_purchase_document
    if received_purchase_order.purchase_order_id.present?
      if received_purchase_order.purchase_order.account_payable_purchase_partials.blank?
        received_purchase_order.purchase_order.update_column(:invoice_status, "")
      end
    else
      if received_purchase_order.direct_purchase.account_payable_purchase_partials.blank?
        received_purchase_order.direct_purchase.update_column(:invoice_status, "")
      end
    end
  end
  
  def mark_purchase_document_invoice_status_as_partial
    if received_purchase_order.purchase_order_id.present?
      received_purchase_order.purchase_order.update_column(:invoice_status, "Partial")
    else
      received_purchase_order.direct_purchase.update_column(:invoice_status, "Partial")
    end
  end
  
  def mark_received_purchase_as_invoiced
    received_purchase_order.update_column(:invoice_status, "Invoiced")
  end
  
  def remove_invoiced_mark_from_received_purchase
    received_purchase_order.update_column(:invoice_status, "")
  end
end
