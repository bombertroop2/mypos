class AccountsReceivablePaymentInvoice < ApplicationRecord
  attr_accessor :attr_invoice_number, :attr_remaining_debt, :attr_amount_sold, :attr_payment_date, :attr_customer_id, :attr_invoice_date, :attr_amount_to_pay
  
  belongs_to :accounts_receivable_payment
  belongs_to :accounts_receivable_invoice
  
  before_validation :convert_attr_invoice_date_to_date, :convert_attr_payment_date_to_date, :set_attr_remaining_debt, :set_attr_amount_to_pay, on: :create
  
  validates :accounts_receivable_invoice_id, :amount, presence: true
  validates :amount, numericality: {greater_than: 0}, if: proc{|arpi| arpi.amount.present?}
    validates :amount, numericality: {less_than_or_equal_to: :attr_amount_to_pay}, if: proc{|arpi| arpi.amount.present?}
      validates :attr_invoice_date, date: {before_or_equal_to: proc { :attr_payment_date }, message: 'must be before or equal to payment date' }, if: proc {|arpi| arpi.attr_payment_date.present?}
            
        after_create :update_invoice_remaining_debt
        
        private
        
        def set_attr_amount_to_pay
          self.attr_amount_to_pay = attr_remaining_debt
        end
        
        def update_invoice_remaining_debt
          @ar_invoice.with_lock do
            @ar_invoice.update_column(:remaining_debt, attr_remaining_debt - amount)
          end
        end
        
        def set_attr_remaining_debt
          @ar_invoice = AccountsReceivableInvoice.joins(shipment: :order_booking).select(:id, :remaining_debt, :total).where(id: accounts_receivable_invoice_id).where(["accounts_receivable_invoices.remaining_debt > 0 AND order_bookings.customer_id = ?", attr_customer_id]).first
          self.attr_remaining_debt = @ar_invoice.remaining_debt
        end
                
        def convert_attr_payment_date_to_date
          self.attr_payment_date = attr_payment_date.to_date if attr_payment_date.present?
        end
        
        def convert_attr_invoice_date_to_date
          self.attr_invoice_date = attr_invoice_date.to_date if attr_invoice_date.present?
        end
      end
