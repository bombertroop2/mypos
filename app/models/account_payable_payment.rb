class AccountPayablePayment < ApplicationRecord
  attr_accessor :attr_payment_method
  audited on: :create
  has_many :account_payable_payment_invoices, dependent: :destroy
  
  accepts_nested_attributes_for :account_payable_payment_invoices, allow_destroy: true


  validates :payment_date, presence: true
  validates :payment_date, date: {before_or_equal_to: proc { Date.current }, message: 'must be before or equal to today' }, if: proc {|app| app.payment_date.present?}
    validate :check_min_invoice_per_payment, on: :create
    validate :transaction_open

    before_destroy :delete_tracks

    private
    
    def delete_tracks
      audits.destroy_all
    end

    def transaction_open
      errors.add(:base, "Sorry, you can't perform this transaction") if payment_date.present? && FiscalYear.joins(:fiscal_months).where(year: payment_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[payment_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
    end
    
    def check_min_invoice_per_payment
      errors.add(:base, "Payment must have at least one AP invoice") if account_payable_payment_invoices.blank?
    end
  end
