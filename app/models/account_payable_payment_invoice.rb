class AccountPayablePaymentInvoice < ApplicationRecord
  include PurchaseReturnsHelper
  attr_accessor :attr_invoice_number, :attr_remaining_debt, :attr_amount_received, :attr_payment_date, :attr_vendor_invoice_number, :attr_vendor_invoice_date, :attr_vendor_id, :attr_amount_to_pay
  
  belongs_to :account_payable_payment
  belongs_to :account_payable
  has_many :allocated_return_items, dependent: :destroy
  has_many :account_payable_purchases, through: :account_payable

  accepts_nested_attributes_for :allocated_return_items
  
  before_validation :convert_attr_vendor_invoice_date_to_date, :convert_attr_payment_date_to_date, :set_attr_remaining_debt, :calculate_total_amount_returned, :set_attr_amount_to_pay, on: :create
  
  validates :account_payable_id, :amount, presence: true
  validates :amount, numericality: {greater_than: 0}, if: proc{|appi| appi.amount.present?}
    validates :amount, numericality: {less_than_or_equal_to: :attr_amount_to_pay}, if: proc{|appi| appi.amount.present?}
      validates :attr_vendor_invoice_date, date: {before_or_equal_to: proc { :attr_payment_date }, message: 'must be before or equal to payment date' }, if: proc {|app| app.attr_payment_date.present?}
        validates :amount_returned, numericality: {less_than: :attr_remaining_debt, message: "must be less than debt"}, if: proc{|appi| appi.allocated_return_items.present?}
            
          after_create :update_account_payable_remaining_debt
        
          private
        
          def set_attr_amount_to_pay
            self.attr_amount_to_pay = attr_remaining_debt - amount_returned
          end
        
          def calculate_total_amount_returned
            self.amount_returned = 0
            if allocated_return_items.present?
              allocated_return_items.each do |allocated_return_item|
                pr = PurchaseReturn.
                  where(["purchase_returns.id = ? AND is_allocated = ? AND (vendors.id = ? OR vendors_direct_purchases.id = ?) AND (vendors.is_active = ? OR vendors_direct_purchases.is_active = ?)", allocated_return_item.purchase_return_id, false, attr_vendor_id, attr_vendor_id, true, true]).
                  joins("LEFT JOIN purchase_orders ON purchase_returns.purchase_order_id = purchase_orders.id").
                  joins("LEFT JOIN vendors ON purchase_orders.vendor_id = vendors.id").
                  joins("LEFT JOIN direct_purchases ON purchase_returns.direct_purchase_id = direct_purchases.id").
                  joins("LEFT JOIN vendors vendors_direct_purchases ON direct_purchases.vendor_id = vendors_direct_purchases.id").
                  select(:id, :purchase_order_id, :direct_purchase_id).first
                self.amount_returned += value_after_ppn_pr(pr)
              end
            end
          end
        
          def update_account_payable_remaining_debt
            @ap_invoice.with_lock do
              @ap_invoice.update_column(:remaining_debt, attr_remaining_debt - amount_returned - amount)
            end
          end
        
          def set_attr_remaining_debt
            @ap_invoice = AccountPayable.joins(:vendor).select(:id, :remaining_debt, :total).where(id: account_payable_id).where(["vendors.is_active = ? AND account_payables.remaining_debt > 0 AND vendors.id = ?", true, attr_vendor_id]).first
            self.attr_remaining_debt = @ap_invoice.remaining_debt
          end
                
          def convert_attr_payment_date_to_date
            self.attr_payment_date = attr_payment_date.to_date if attr_payment_date.present?
          end

          def convert_attr_vendor_invoice_date_to_date
            self.attr_vendor_invoice_date = attr_vendor_invoice_date.to_date if attr_vendor_invoice_date.present?
          end
        end
