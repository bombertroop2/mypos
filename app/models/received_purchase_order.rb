class ReceivedPurchaseOrder < ApplicationRecord
  audited on: :create

  belongs_to :purchase_order
  belongs_to :direct_purchase
  belongs_to :vendor
  has_many :received_purchase_order_products, dependent: :destroy
  has_many :account_payable_purchase_partials, dependent: :restrict_with_error
  
  
  accepts_nested_attributes_for :received_purchase_order_products, reject_if: :child_blank
  
  before_validation :strip_string_values, unless: proc{|rpo| rpo.is_using_delivery_order.eql?("no")}, on: :create
    before_validation :set_empty_value_to_delivery_order_number, if: proc{|rpo| rpo.is_using_delivery_order.eql?("no")}, on: :create
      
      validates :delivery_order_number, presence: true, unless: proc{|rpo| rpo.is_using_delivery_order.eql?("no")}, on: :create
        validate :purchase_order_not_double_received_per_today, if: proc{|rpo| !rpo.is_using_delivery_order.eql?("no") && rpo.delivery_order_number.present? && rpo.purchase_order_id.present?}, on: :create
          validate :delivery_order_number_not_received, :delivery_order_number_valid, if: proc{|rpo| !rpo.is_using_delivery_order.eql?("no") && rpo.delivery_order_number.present?}, on: :create
            validate :minimum_receiving_item, on: :create, unless: proc {|rpo| rpo.is_it_direct_purchasing}
              validates :receiving_date, presence: true, on: :create, unless: proc {|rpo| rpo.is_it_direct_purchasing}
                validates :receiving_date, date: {after: proc {|rpo| rpo.purchase_order.purchase_order_date}, message: 'must be greater than purchase order date' }, on: :create, if: proc {|rpo| !rpo.is_it_direct_purchasing && rpo.receiving_date.present?}
                  validates :receiving_date, date: {before_or_equal_to: proc { Date.current }, message: 'must be before or equal to today' }, on: :create, if: proc {|rpo| !rpo.is_it_direct_purchasing && rpo.receiving_date.present?}
                    validates :purchase_order_id, presence: true, unless: proc {|rpo| rpo.is_it_direct_purchasing}
                      validate :purchase_order_receivable, unless: proc{|rpo| rpo.is_it_direct_purchasing}
                        validates :vendor_id, presence: true, if: proc{|rpo| rpo.is_it_direct_purchasing}, on: :create
                          validate :transaction_open, if: proc{|rpo| !rpo.is_it_direct_purchasing && rpo.receiving_date.present?}

                            before_create :direct_purchase_not_received, :direct_purchase_not_double_received_per_today, if: proc{|rpo| rpo.is_it_direct_purchasing}
                              before_create :calculate_total_quantity, unless: proc{|rpo| rpo.is_it_direct_purchasing}
                                before_create :generate_transaction_number
      
                                attr_accessor :is_it_direct_purchasing
  
                                private
                                                    
                                def transaction_open                            
                                  errors.add(:base, "Sorry, you can't perform this transaction") if FiscalYear.joins(:fiscal_months).where(year: receiving_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[receiving_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                                end
                    
                                def strip_string_values
                                  self.delivery_order_number = delivery_order_number.strip.gsub(" ","").gsub("\t","").upcase
                                end
                  
                                def purchase_order_receivable
                                  errors.add(:base, "Not able to receive selected PO") unless (@po = PurchaseOrder.joins(:vendor).select(:is_taxable_entrepreneur, "vendors.code AS vendor_code").where(["vendors.is_active = ?", true]).where("(purchase_orders.status = 'Open' OR purchase_orders.status = 'Partial') AND purchase_orders.id = '#{purchase_order_id}' AND purchase_orders.vendor_id = '#{vendor_id}'").first).present?
                                end
                
                                def calculate_total_quantity
                                  self.quantity = 0
                                  received_purchase_order_products.each do |received_purchase_order_product|
                                    self.quantity += received_purchase_order_product.received_purchase_order_items.map(&:quantity).sum
                                  end
                                end
    
                                def minimum_receiving_item
                                  errors.add(:base, "Please insert at least one item") if received_purchase_order_products.blank?
                                end
    
                                def child_blank(attributed)
                                  attributed[:received_purchase_order_items_attributes].each do |key, value| 
                                    return false if value[:quantity].present?
                                  end
      
                                  return true
                                end
                            
                                def purchase_order_not_double_received_per_today
                                  if purchase_order_id.present?
                                    rpo = ReceivedPurchaseOrder.select(:receiving_date, "purchase_orders.number AS po_number").joins(:purchase_order).where(["delivery_order_number = ? AND purchase_order_id = ?", delivery_order_number, purchase_order_id]).first
                                    if rpo.present? && rpo.receiving_date == receiving_date
                                      errors.add(:base, "Sorry, you can receive #{rpo.po_number} (DO No. #{delivery_order_number}) only once per day")
                                    end                              
                                  end
                                end

                                def delivery_order_number_not_received
                                  @rpo = ReceivedPurchaseOrder.
                                    select(:receiving_date, :vendor_id, :direct_purchase_id).
                                    where(["delivery_order_number = ?", delivery_order_number]).
                                    first
                                  if purchase_order_id.present? && @rpo.present? && @rpo.receiving_date != receiving_date
                                    errors.add(:delivery_order_number, "has already been received")
                                  end                              
                                end

                                def direct_purchase_not_received
                                  if @rpo.present? && @rpo.receiving_date != receiving_date
                                    raise "has already been received"
                                  end                              
                                end
                                
                                def set_empty_value_to_delivery_order_number
                                  self.delivery_order_number = ""
                                end

                                def generate_transaction_number
                                  pkp_code = if purchase_order_id.present?
                                    @po.is_taxable_entrepreneur ? "1" : "0"
                                  else
                                    vendor = Vendor.select(:code, :is_taxable_entrepreneur).find(vendor_id)
                                    vendor.is_taxable_entrepreneur ? "1" : "0"
                                  end
                                  current_month = receiving_date.month.to_s.rjust(2, '0')
                                  current_year = receiving_date.strftime("%y").rjust(2, '0')
                                  vendor_code = if purchase_order_id.present?
                                    @po.vendor_code
                                  else
                                    vendor.code
                                  end
                                  existed_numbers = ReceivedPurchaseOrder.where("transaction_number LIKE '#{pkp_code}RCV#{vendor_code}#{current_month}#{current_year}%'").select(:transaction_number).order(:transaction_number)
                                  if existed_numbers.blank?
                                    new_number = "#{pkp_code}RCV#{vendor_code}#{current_month}#{current_year}0001"
                                  else
                                    if existed_numbers.length == 1
                                      seq_number = existed_numbers[0].transaction_number.split("#{pkp_code}RCV#{vendor_code}#{current_month}#{current_year}").last
                                      if seq_number.to_i > 1
                                        new_number = "#{pkp_code}RCV#{vendor_code}#{current_month}#{current_year}0001"
                                      else
                                        new_number = "#{pkp_code}RCV#{vendor_code}#{current_month}#{current_year}#{seq_number.succ}"
                                      end
                                    else
                                      last_seq_number = ""
                                      existed_numbers.each_with_index do |existed_number, index|
                                        seq_number = existed_number.transaction_number.split("#{pkp_code}RCV#{vendor_code}#{current_month}#{current_year}").last
                                        if seq_number.to_i > 1 && index == 0
                                          new_number = "#{pkp_code}RCV#{vendor_code}#{current_month}#{current_year}0001"
                                          break                              
                                        elsif last_seq_number.eql?("")
                                          last_seq_number = seq_number
                                        elsif (seq_number.to_i - last_seq_number.to_i) > 1
                                          new_number = "#{pkp_code}RCV#{vendor_code}#{current_month}#{current_year}#{last_seq_number.succ}"
                                          break
                                        elsif index == existed_numbers.length - 1
                                          new_number = "#{pkp_code}RCV#{vendor_code}#{current_month}#{current_year}#{seq_number.succ}"
                                        else
                                          last_seq_number = seq_number
                                        end
                                      end
                                    end                        
                                  end
                                  self.transaction_number = new_number
                                end
                            
                                def delivery_order_number_valid
                                  if @rpo.present? && vendor_id != @rpo.vendor_id
                                    errors.add(:delivery_order_number, "is not valid")
                                  end
                                end
                                
                                def direct_purchase_not_double_received_per_today
                                  if @rpo.present? && @rpo.receiving_date == receiving_date && @rpo.direct_purchase_id.present? && @rpo.vendor_id == vendor_id
                                    errors.add(:base, "Sorry, you can receive DO #{delivery_order_number} only once per day")
                                    throw :abort
                                  end                              
                                end
                              end
