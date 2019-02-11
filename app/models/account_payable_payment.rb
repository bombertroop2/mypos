class AccountPayablePayment < ApplicationRecord
  attr_accessor :attr_vendor_code_and_name, :attr_company_bank_id
  audited on: :create
  has_many :account_payable_payment_invoices, dependent: :destroy
  belongs_to :vendor
  belongs_to :bank
  belongs_to :company_bank_account_number
  
  accepts_nested_attributes_for :account_payable_payment_invoices, allow_destroy: true
  
  before_validation :strip_string_values

  validates :payment_date, :payment_method, :vendor_id, presence: true
  validates :attr_company_bank_id, :company_bank_account_number_id, presence: true, if: proc{|app| app.payment_method.eql?("Transfer")}
    validates :payment_date, date: {before_or_equal_to: proc { Date.current }, message: 'must be before or equal to today' }, if: proc {|app| app.payment_date.present?}
      validate :check_min_invoice_per_payment, on: :create
      validate :transaction_open, :payment_method_available, :vendor_available, :payment_date_after_or_equal_to_latest_payment_date
      validate :bank_account_number_available, if: proc{|app| app.payment_method.eql?("Transfer") && app.company_bank_account_number_id.present?}
        validates :giro_number, :giro_date, presence: true, if: proc {|app| app.payment_method.eql?("Giro")}
          validates :giro_date, date: {before_or_equal_to: proc {|app| app.payment_date}, message: 'must be before or equal to payment date' }, if: proc {|app| app.giro_date.present? && app.payment_date.present? && app.payment_method.eql?("Giro")}
            validates :giro_date, date: {before_or_equal_to: proc {Date.current}, message: 'must be before or equal to today' }, if: proc {|app| app.giro_date.present? && app.payment_method.eql?("Giro")}
              validates :giro_number, uniqueness: true, if: proc {|app| app.payment_method.eql?("Giro")}

                before_create :generate_number
                before_destroy :delete_tracks
    
                PAYMENT_METHODS = [
                  ["Cash", "Cash"],
                  ["Giro", "Giro"],
                  ["Transfer", "Transfer"]
                ]

                private
                
                def payment_date_after_or_equal_to_latest_payment_date
                  if payment_date.present?
                    account_payable_payment_invoices.each do |account_payable_payment_invoice|
                      latest_account_payable_payment_invoice = AccountPayablePaymentInvoice.select("account_payable_payments.payment_date").joins(:account_payable_payment).where(account_payable_id: account_payable_payment_invoice.account_payable_id).order("account_payable_payments.payment_date DESC").first
                      if latest_account_payable_payment_invoice.present? && payment_date < latest_account_payable_payment_invoice.payment_date
                        errors.add(:payment_date, "must be after or equal to #{latest_account_payable_payment_invoice.payment_date.strftime("%d/%m/%Y")}")
                        break
                      end
                    end
                  end
                end
    
                def strip_string_values
                  self.giro_number = giro_number.strip if payment_method.eql?("Giro")
                end
    
                def delete_tracks
                  audits.destroy_all
                end

                def transaction_open
                  errors.add(:base, "Sorry, you can't perform this transaction") if payment_date.present? && FiscalYear.joins(:fiscal_months).where(year: payment_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[payment_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                end
    
                def check_min_invoice_per_payment
                  errors.add(:base, "Payment must have at least one AP invoice") if account_payable_payment_invoices.blank?
                end
    
                def payment_method_available
                  PAYMENT_METHODS.select{ |x| x[1] == payment_method }.first.first
                rescue
                  errors.add(:payment_method, "does not exist!") if payment_method.present?
                end
    
                def vendor_available
                  errors.add(:vendor_id, "does not exist!") if (@vendor = Vendor.select(:code, :is_taxable_entrepreneur).where(id: vendor_id, is_active: true).first).blank?
                end

                def bank_account_number_available
                  errors.add(:company_bank_account_number_id, "does not exist!") if CompanyBankAccountNumber.select("1 AS one").where(id: company_bank_account_number_id, company_bank_id: attr_company_bank_id).blank?
                end
    
                def generate_number
                  is_taxable_entrepreneur = @vendor.is_taxable_entrepreneur
                  pkp_code = is_taxable_entrepreneur ? "1" : "0"
                  current_month = payment_date.month.to_s.rjust(2, '0')
                  current_year = payment_date.strftime("%y").rjust(2, '0')
                  existed_numbers = AccountPayablePayment.where("number LIKE '#{pkp_code}PY#{@vendor.code}#{current_month}#{current_year}%'").select(:number).order(:number)
                  if existed_numbers.blank?
                    new_number = "#{pkp_code}PY#{@vendor.code}#{current_month}#{current_year}0001"
                  else
                    if existed_numbers.length == 1
                      seq_number = existed_numbers[0].number.split("#{pkp_code}PY#{@vendor.code}#{current_month}#{current_year}").last
                      if seq_number.to_i > 1
                        new_number = "#{pkp_code}PY#{@vendor.code}#{current_month}#{current_year}0001"
                      else
                        new_number = "#{pkp_code}PY#{@vendor.code}#{current_month}#{current_year}#{seq_number.succ}"
                      end
                    else
                      last_seq_number = ""
                      existed_numbers.each_with_index do |existed_number, index|
                        seq_number = existed_number.number.split("#{pkp_code}PY#{@vendor.code}#{current_month}#{current_year}").last
                        if seq_number.to_i > 1 && index == 0
                          new_number = "#{pkp_code}PY#{@vendor.code}#{current_month}#{current_year}0001"
                          break                              
                        elsif last_seq_number.eql?("")
                          last_seq_number = seq_number
                        elsif (seq_number.to_i - last_seq_number.to_i) > 1
                          new_number = "#{pkp_code}PY#{@vendor.code}#{current_month}#{current_year}#{last_seq_number.succ}"
                          break
                        elsif index == existed_numbers.length - 1
                          new_number = "#{pkp_code}PY#{@vendor.code}#{current_month}#{current_year}#{seq_number.succ}"
                        else
                          last_seq_number = seq_number
                        end
                      end
                    end                        
                  end
                  self.number = new_number
                end
              end
