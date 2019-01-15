class AccountPayable < ApplicationRecord
  include AccountPayablesHelper
  include PurchaseReturnsHelper
  
  audited on: :create

  attr_accessor :payment_for_dp
  
  INVOICE_STATUSES = [
    ["Invoiced", "Invoiced"],
    ["Not Yet Invoiced", ""]
  ]
  PAYMENT_METHODS = [
    ["Cash", "Cash"],
    ["Giro", "Giro"],
    ["Transfer", "Transfer"]
  ]
  
  belongs_to :vendor
  has_many :account_payable_purchases, dependent: :destroy
  has_many :allocated_return_items, dependent: :destroy
  
  accepts_nested_attributes_for :account_payable_purchases
  accepts_nested_attributes_for :allocated_return_items
  
  before_validation :strip_string_values
  before_validation :set_amount_returned, :set_total, on: :create

  validates :payment_date, :payment_method, :vendor_id, :vendor_invoice_number, :vendor_invoice_date, presence: true
  validates :vendor_invoice_number, uniqueness: true
  validates :vendor_invoice_date, date: {before_or_equal_to: proc { Date.current }, message: 'must be before or equal to today' }, if: proc {|ap| ap.vendor_invoice_date.present?}
    validates :giro_number, :giro_date, presence: true, if: proc {|ap| ap.payment_method.eql?("Giro")}
      validates :giro_date, date: {before_or_equal_to: proc {|ap| ap.payment_date}, message: 'must be before or equal to payment date' }, if: proc {|ap| ap.giro_date.present? && ap.payment_date.present? && ap.payment_method.eql?("Giro")}
        validates :payment_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|ap| ap.payment_date.present?}
          validates :total, numericality: {greater_than: 0}
          validates :total, numericality: {greater_than: :amount_returned}
          validate :payment_method_available, :vendor_available, :amount_to_be_paid_should_greater_than_zero, on: :create
            
          before_create :generate_number, :set_remaining_debt
          after_create :mark_purchase_doc_as_paid              
          before_destroy :delete_tracks
                                        
          private                   
                        
          def delete_tracks
            audits.destroy_all
          end
  
          def strip_string_values
            if payment_method.eql?("Giro")
              self.giro_number = giro_number.strip
            end
            self.vendor_invoice_number = vendor_invoice_number.strip
          end
                    
          def vendor_available
            errors.add(:vendor_id, "does not exist!") if Vendor.select("1 AS one").where(id: vendor_id, is_active: true).blank?
          end
                    
          def payment_method_available
            PAYMENT_METHODS.select{ |x| x[1] == payment_method }.first.first
          rescue
            errors.add(:payment_method, "does not exist!") if payment_method.present?
          end
                    
          def set_amount_returned
            self.amount_returned = 0
            allocated_return_items.each do |allocated_return_item|
              self.amount_returned += value_after_ppn_pr(allocated_return_item.purchase_return)
            end
          end
                    
          def generate_number
            is_taxable_entrepreneur = vendor.is_taxable_entrepreneur rescue nil
            pkp_code = is_taxable_entrepreneur ? "1" : "0"
            today = Date.current
            current_month = today.month.to_s.rjust(2, '0')
            current_year = today.strftime("%y").rjust(2, '0')
            existed_numbers = AccountPayable.where("number LIKE '#{pkp_code}PY#{vendor.code}#{current_month}#{current_year}%'").select(:number).order(:number)
            if existed_numbers.blank?
              new_number = "#{pkp_code}PY#{vendor.code}#{current_month}#{current_year}0001"
            else
              if existed_numbers.length == 1
                seq_number = existed_numbers[0].number.split("#{pkp_code}PY#{vendor.code}#{current_month}#{current_year}").last
                if seq_number.to_i > 1
                  new_number = "#{pkp_code}PY#{vendor.code}#{current_month}#{current_year}0001"
                else
                  new_number = "#{pkp_code}PY#{vendor.code}#{current_month}#{current_year}#{seq_number.succ}"
                end
              else
                last_seq_number = ""
                existed_numbers.each_with_index do |existed_number, index|
                  seq_number = existed_number.number.split("#{pkp_code}PY#{vendor.code}#{current_month}#{current_year}").last
                  if seq_number.to_i > 1 && index == 0
                    new_number = "#{pkp_code}PY#{vendor.code}#{current_month}#{current_year}0001"
                    break                              
                  elsif last_seq_number.eql?("")
                    last_seq_number = seq_number
                  elsif (seq_number.to_i - last_seq_number.to_i) > 1
                    new_number = "#{pkp_code}PY#{vendor.code}#{current_month}#{current_year}#{last_seq_number.succ}"
                    break
                  elsif index == existed_numbers.length - 1
                    new_number = "#{pkp_code}PY#{vendor.code}#{current_month}#{current_year}#{seq_number.succ}"
                  else
                    last_seq_number = seq_number
                  end
                end
              end                        
            end
            self.number = new_number
          end
          
          def mark_purchase_doc_as_paid
            account_payable_purchases.select(:purchase_id, :purchase_type).each do |app|
              app.purchase.update_attribute(:invoice_status, "Invoiced")
            end
          end
          
          def set_total
            self.total = 0
            account_payable_purchases.each do |account_payable_purchase|
              self.total += value_after_ppn_for_ap(account_payable_purchase.purchase)
            end
          end
          
          def set_remaining_debt
            self.remaining_debt = total
          end
            
          def amount_to_be_paid_should_greater_than_zero
            errors.add(:base, "Amount due must be greater than 0") if total - amount_returned <= 0
          end

        end
