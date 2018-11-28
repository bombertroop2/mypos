class AccountPayable < ApplicationRecord
  include AccountPayablesHelper
  include PurchaseReturnsHelper
  
  audited on: :create

  attr_accessor :amount_to_be_paid, :total_amount_returned, :payment_for_dp
  
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
  
  before_validation :calculate_amount_to_be_paid, :set_zero_debt, :strip_string_values

  validates :payment_date, :payment_method, :amount_paid, :vendor_id, :debt, presence: true
  validates :giro_number, :giro_date, presence: true, if: proc {|ap| ap.payment_method.eql?("Giro")}
    validates :giro_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|ap| ap.giro_date.present? && ap.payment_method.eql?("Giro")}
      validates :giro_date, date: {after_or_equal_to: proc {|ap| ap.payment_date}, message: 'must be after or equal to payment date' }, if: proc {|ap| ap.giro_date.present? && ap.payment_date.present? && ap.payment_method.eql?("Giro")}
        validates :payment_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|ap| ap.payment_date.present?}
          validates :amount_paid, numericality: true, if: proc { |ap| ap.amount_paid.present? }
            validates :amount_paid, numericality: {greater_than: 0}, if: proc { |ap| ap.amount_paid.present? && ap.amount_paid.is_a?(Numeric) }
              validates :amount_paid, numericality: {less_than_or_equal_to: :amount_to_be_paid}, if: proc { |ap| ap.amount_paid.present? && ap.amount_paid.is_a?(Numeric) }, on: :create
                validates :debt, numericality: true, if: proc { |ap| ap.debt.present? }
                  validates :debt, numericality: {greater_than_or_equal_to: 0}, if: proc { |ap| ap.debt.present? && ap.debt.is_a?(Numeric) }
                    validate :calculate_amount_paid_and_debt, if: proc{|ap| ap.amount_paid.present? && ap.amount_paid.is_a?(Numeric) && ap.debt.present? && ap.debt.is_a?(Numeric) && ap.amount_paid > 0}, on: :create
                      validate :amount_to_be_paid_should_greater_than_zero,
                        :payment_method_available, :vendor_available, on: :create
            
                      before_create :generate_number, :set_amount_returned
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
                      end
                    
                      def vendor_available
                        errors.add(:vendor_id, "does not exist!") if Vendor.select("1 AS one").where(id: vendor_id).blank?
                      end
                    
                      def payment_method_available
                        PAYMENT_METHODS.select{ |x| x[1] == payment_method }.first.first
                      rescue
                        errors.add(:payment_method, "does not exist!") if payment_method.present?
                      end
                    
                      def set_amount_returned
                        self.amount_returned = total_amount_returned
                      end
                    
                      def amount_to_be_paid_should_greater_than_zero
                        errors.add(:base, "Amount due must be greater than 0") if amount_to_be_paid <= 0
                      end
                    
                      def set_zero_debt
                        self.debt = 0 if amount_paid == amount_to_be_paid
                      end
                    
                      def calculate_amount_paid_and_debt
                        if amount_paid + debt != amount_to_be_paid
                          errors.add(:amount_paid, "is wrong!")
                          errors.add(:debt, "is wrong!")
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
                        if amount_paid == amount_to_be_paid
                          account_payable_purchases.select(:purchase_id, :purchase_type).each do |app|
                            app.purchase.update_attribute(:invoice_status, "Invoiced")
                          end
                        end
                      end
          
                      def calculate_amount_to_be_paid
                        amount_to_be_paid = 0
                        account_payable_purchases.each do |account_payable_purchase|
                          amount_to_be_paid += value_after_ppn_for_ap(account_payable_purchase.purchase)
                        end
                      
                        previous_account_payables = []
                        account_payable_purchases.map(&:purchase_id).each do |purchase_order_id|
                          account_payables = if payment_for_dp
                            AccountPayable.select(:id, :amount_paid, :amount_returned).joins(:account_payable_purchases).where("purchase_id = '#{purchase_order_id}' AND purchase_type = 'DirectPurchase'")
                          else
                            AccountPayable.select(:id, :amount_paid, :amount_returned).joins(:account_payable_purchases).where("purchase_id = '#{purchase_order_id}' AND purchase_type = 'PurchaseOrder'")
                          end
                          account_payables.each do |account_payable|        
                            previous_account_payables << account_payable
                          end
                        end    
    
                        # potong dengan PR apabila PR dialokasikan
                        self.total_amount_returned = 0
                        allocated_return_items.each do |allocated_return_item|
                          self.total_amount_returned += value_after_ppn_pr(allocated_return_item.purchase_return)
                        end

                        # kalkulasi pembayaran pembayaran sebelumnya
                        self.previous_paid = 0
                        previous_account_payables.uniq.each do |previous_account_payable|
                          self.previous_paid += previous_account_payable.amount_paid + previous_account_payable.amount_returned.to_f
                        end
                              
                        self.amount_to_be_paid = amount_to_be_paid - total_amount_returned - previous_paid
                      end
          
                    end
