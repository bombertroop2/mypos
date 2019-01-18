class AccountPayablePaymentInvoice < ApplicationRecord
  attr_accessor :attr_vendor_code_and_name, :attr_invoice_number, :attr_amount_returned, :attr_invoice_payment_date, :attr_remaining_debt, :attr_amount_received, :attr_payment_date, :attr_payment_method
  
  belongs_to :account_payable_payment
  belongs_to :account_payable
  
  before_validation :convert_attr_invoice_payment_date_to_date, :convert_attr_payment_date_to_date, :set_attr_remaining_debt, on: :create
  
  validates :account_payable_id, presence: true
  validates :amount, presence: true, unless: proc{|appi| appi.attr_payment_method.eql?("Giro")}
    validates :amount, numericality: {greater_than: 0}, if: proc{|appi| appi.amount.present? && !appi.attr_payment_method.eql?("Giro")}
      validates :amount, numericality: {less_than_or_equal_to: :attr_remaining_debt, message: "must be less than or equal to debt"}, if: proc{|appi| appi.amount.present? && !appi.attr_payment_method.eql?("Giro")}
        validates :attr_invoice_payment_date, date: {before_or_equal_to: :attr_payment_date, message: 'must be before or equal to payment date' }, if: proc {|appi| appi.attr_payment_date.present?}
               
          before_create :set_amount, if: proc{|appi| appi.attr_payment_method.eql?("Giro")}
            
            after_create :update_account_payable_remaining_debt
            after_create :update_account_payable_payment_amount, if: proc{|appi| appi.attr_payment_method.eql?("Giro")}
        
              private
              
              def set_amount
                self.amount = attr_remaining_debt
              end
          
              def update_account_payable_payment_amount
                account_payable_payment.with_lock do
                  account_payable_payment.update_column(:amount, account_payable_payment.amount.to_f + attr_remaining_debt)
                end
              end
        
              def update_account_payable_remaining_debt
                @ap_invoice.with_lock do
                  unless attr_payment_method.eql?("Giro")
                    @ap_invoice.update_column(:remaining_debt, attr_remaining_debt - amount)
                  else
                    @ap_invoice.update_column(:remaining_debt, 0)
                  end
                end
              end
        
              def set_attr_remaining_debt
                @ap_invoice = AccountPayable.joins(:vendor).select(:id, :amount_returned, :remaining_debt, :total).where(id: account_payable_id, payment_method: attr_payment_method).where(["vendors.is_active = ? AND account_payables.remaining_debt > 0", true]).first
                self.attr_remaining_debt = if @ap_invoice.total == @ap_invoice.remaining_debt
                  @ap_invoice.total - @ap_invoice.amount_returned
                else
                  @ap_invoice.remaining_debt
                end
              end
        
              def convert_attr_invoice_payment_date_to_date
                self.attr_invoice_payment_date = attr_invoice_payment_date.to_date
              end
        
              def convert_attr_payment_date_to_date
                self.attr_payment_date = attr_payment_date.to_date if attr_payment_date.present?
              end
            end
