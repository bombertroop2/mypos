class AccountPayableCourierPaymentInvoice < ApplicationRecord
  attr_accessor :attr_invoice_number, :attr_remaining_debt, :attr_amount_invoiced, :attr_payment_date, :attr_courier_invoice_number, :attr_courier_invoice_date, :attr_courier_id, :attr_amount_to_pay

  belongs_to :account_payable_courier_payment
  belongs_to :account_payable_courier
  has_many :packing_lists, through: :account_payable_courier
  
  before_validation :convert_attr_courier_invoice_date_to_date, :convert_attr_payment_date_to_date, :set_attr_remaining_debt, :set_attr_amount_to_pay, on: :create
  
  validates :account_payable_courier_id, :amount, presence: true
  validates :amount, numericality: {greater_than: 0}, if: proc{|appi| appi.amount.present?}
    validates :amount, numericality: {less_than_or_equal_to: :attr_amount_to_pay}, if: proc{|appi| appi.amount.present?}
      validates :attr_courier_invoice_date, date: {before_or_equal_to: proc { :attr_payment_date }, message: 'must be before or equal to payment date' }, if: proc {|app| app.attr_payment_date.present?}
            
        after_create :update_account_payable_remaining_debt
        
        private
        
        def set_attr_amount_to_pay
          self.attr_amount_to_pay = attr_remaining_debt
        end
                
        def update_account_payable_remaining_debt
          @ap_invoice.with_lock do
            @ap_invoice.update_column(:remaining_debt, attr_remaining_debt - amount)
          end
        end
        
        def set_attr_remaining_debt
          @ap_invoice = AccountPayableCourier.joins(:courier).select(:id, :remaining_debt, :total).where(id: account_payable_courier_id).where(["couriers.status = 'External' AND account_payable_couriers.remaining_debt > 0 AND couriers.id = ?", attr_courier_id]).first
          self.attr_remaining_debt = @ap_invoice.remaining_debt
        end
                
        def convert_attr_payment_date_to_date
          self.attr_payment_date = attr_payment_date.to_date if attr_payment_date.present?
        end

        def convert_attr_courier_invoice_date_to_date
          self.attr_courier_invoice_date = attr_courier_invoice_date.to_date if attr_courier_invoice_date.present?
        end
      end
