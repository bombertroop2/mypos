class AccountPayable < ApplicationRecord
  include AccountPayablesHelper
  include PurchaseReturnsHelper
  
  audited on: :create

  INVOICE_STATUSES = [
    ["Invoiced", "Invoiced"],
    ["Not Yet Invoiced", ""]
  ]

  BEGINNING_OF_AP_CREATINGS = [
    ["Closed/Finish", "Closed/Finish"],
    ["Partial", "Partial"]
  ]
  
  belongs_to :vendor
  has_many :account_payable_purchases, dependent: :destroy
  has_many :account_payable_purchase_partials, dependent: :destroy
  has_many :account_payable_payment_invoices, dependent: :restrict_with_error
  
  accepts_nested_attributes_for :account_payable_purchases
  accepts_nested_attributes_for :account_payable_purchase_partials
  
  before_validation :strip_string_values
  before_validation :set_total, on: :create

  validates :vendor_id, :vendor_invoice_number, :vendor_invoice_date, presence: true
  validates :vendor_invoice_number, uniqueness: true
  validates :vendor_invoice_date, date: {before_or_equal_to: proc { Date.current }, message: 'must be before or equal to today' }, if: proc {|ap| ap.vendor_invoice_date.present?}
    validates :total, numericality: {greater_than: 0}
    validate :vendor_available, :beginning_of_account_payable_creating_available, :check_min_purchase_per_invoice, on: :create

    
    before_create :generate_number, :set_remaining_debt
    after_create :mark_purchase_doc_as_paid              
    before_destroy :delete_tracks
                                          
    private
    
    def check_min_purchase_per_invoice
      errors.add(:base, "Invoice must have at least one purchase") if beginning_of_account_payable_creating.eql?("Closed/Finish") && account_payable_purchases.blank?
      errors.add(:base, "Invoice must have at least one purchase") if beginning_of_account_payable_creating.eql?("Partial") && account_payable_purchase_partials.blank?
    end
                        
    def delete_tracks
      audits.destroy_all
    end
  
    def strip_string_values
      self.vendor_invoice_number = vendor_invoice_number.strip
    end
                    
    def vendor_available
      errors.add(:vendor_id, "does not exist!") if Vendor.select("1 AS one").where(id: vendor_id, is_active: true).blank?
    end
                                        
    def generate_number
      is_taxable_entrepreneur = vendor.is_taxable_entrepreneur rescue nil
      pkp_code = is_taxable_entrepreneur ? "1" : "0"
      today = Date.current
      current_month = today.month.to_s.rjust(2, '0')
      current_year = today.strftime("%y").rjust(2, '0')
      existed_numbers = AccountPayable.where("number LIKE '#{pkp_code}INV#{vendor.code}#{current_month}#{current_year}%'").select(:number).order(:number)
      if existed_numbers.blank?
        new_number = "#{pkp_code}INV#{vendor.code}#{current_month}#{current_year}0001"
      else
        if existed_numbers.length == 1
          seq_number = existed_numbers[0].number.split("#{pkp_code}INV#{vendor.code}#{current_month}#{current_year}").last
          if seq_number.to_i > 1
            new_number = "#{pkp_code}INV#{vendor.code}#{current_month}#{current_year}0001"
          else
            new_number = "#{pkp_code}INV#{vendor.code}#{current_month}#{current_year}#{seq_number.succ}"
          end
        else
          last_seq_number = ""
          existed_numbers.each_with_index do |existed_number, index|
            seq_number = existed_number.number.split("#{pkp_code}INV#{vendor.code}#{current_month}#{current_year}").last
            if seq_number.to_i > 1 && index == 0
              new_number = "#{pkp_code}INV#{vendor.code}#{current_month}#{current_year}0001"
              break                              
            elsif last_seq_number.eql?("")
              last_seq_number = seq_number
            elsif (seq_number.to_i - last_seq_number.to_i) > 1
              new_number = "#{pkp_code}INV#{vendor.code}#{current_month}#{current_year}#{last_seq_number.succ}"
              break
            elsif index == existed_numbers.length - 1
              new_number = "#{pkp_code}INV#{vendor.code}#{current_month}#{current_year}#{seq_number.succ}"
            else
              last_seq_number = seq_number
            end
          end
        end                        
      end
      self.number = new_number
    end
          
    def mark_purchase_doc_as_paid
      unless beginning_of_account_payable_creating.eql?("Partial")
        account_payable_purchases.select(:purchase_id, :purchase_type).each do |app|
          app.purchase.update_attribute(:invoice_status, "Invoiced")
        end
      end
    end
          
    def set_total
      self.total = 0
      if beginning_of_account_payable_creating.eql?("Partial")
        account_payable_purchase_partials.each do |account_payable_purchase_partial|
          rpo = ReceivedPurchaseOrder.
            select(:id, :direct_purchase_id, :purchase_order_id, :quantity, "purchase_orders.first_discount AS po_first_discount", "direct_purchases.first_discount AS dp_first_discount", "purchase_orders.second_discount AS po_second_discount", "direct_purchases.second_discount AS dp_second_discount", "purchase_orders.is_additional_disc_from_net AS po_is_additional_disc_from_net", "direct_purchases.is_additional_disc_from_net AS dp_is_additional_disc_from_net", "purchase_orders.is_taxable_entrepreneur AS po_is_taxable_entrepreneur", "direct_purchases.is_taxable_entrepreneur AS dp_is_taxable_entrepreneur", "purchase_orders.value_added_tax AS po_vat_type", "direct_purchases.vat_type AS dp_vat_type").
            joins(:vendor).
            joins("LEFT JOIN purchase_orders ON received_purchase_orders.purchase_order_id = purchase_orders.id").
            joins("LEFT JOIN direct_purchases ON received_purchase_orders.direct_purchase_id = direct_purchases.id").
            where(vendor_id: vendor_id, invoice_status: "").
            where(["vendors.is_active = ? AND (purchase_orders.invoice_status <> 'Invoiced' OR direct_purchases.invoice_status <> 'Invoiced') AND received_purchase_orders.receiving_date <= ?", true, vendor_invoice_date]).
            find(account_payable_purchase_partial.received_purchase_order_id)
          gross_amount = 0
          rpo.received_purchase_order_products.includes(:received_purchase_order_items, purchase_order_product: :cost_list, direct_purchase_product: :cost_list).each do |rpop|
            rpop.received_purchase_order_items.each do |rpoi|
              if rpop.purchase_order_product_id.present?
                gross_amount += rpoi.quantity * rpop.purchase_order_product.cost_list.cost
              else
                gross_amount += rpoi.quantity * rpop.direct_purchase_product.cost_list.cost
              end
            end
          end
          first_discount = if rpo.purchase_order_id.present? && rpo.po_first_discount.present?
            rpo.po_first_discount
          elsif rpo.direct_purchase_id.present? && rpo.dp_first_discount.present?
            rpo.dp_first_discount
          end
          first_discount_money = if rpo.purchase_order_id.present? && rpo.po_first_discount.present?
            (rpo.po_first_discount.to_f / 100) * gross_amount
          elsif rpo.direct_purchase_id.present? && rpo.dp_first_discount.present?
            (rpo.dp_first_discount.to_f / 100) * gross_amount
          end
          second_discount = if rpo.purchase_order_id.present? && rpo.po_second_discount.present?
            rpo.po_second_discount
          elsif rpo.direct_purchase_id.present? && rpo.dp_second_discount.present?
            rpo.dp_second_discount
          end
          second_discount_money = if rpo.purchase_order_id.present? && rpo.po_second_discount.present?
            get_second_discount_in_money_for_ap_partial rpo, "order", gross_amount
          elsif rpo.direct_purchase_id.present? && rpo.dp_second_discount.present?
            get_second_discount_in_money_for_ap_partial rpo, "direct", gross_amount        
          end
          is_additional_disc_from_net = if rpo.purchase_order_id.present? && rpo.po_second_discount.present?
            rpo.po_is_additional_disc_from_net
          elsif rpo.direct_purchase_id.present? && rpo.dp_second_discount.present?
            rpo.dp_is_additional_disc_from_net
          end
          is_taxable_entrepreneur = if rpo.purchase_order_id.present?
            rpo.po_is_taxable_entrepreneur
          else
            rpo.dp_is_taxable_entrepreneur
          end
          vat_in_money = if is_taxable_entrepreneur && rpo.purchase_order_id.present?
            if rpo.po_vat_type.eql?("include")
              get_include_vat_in_money_for_ap_partial rpo, "order", gross_amount
            else
              get_vat_in_money_for_ap_partial rpo, "order", gross_amount
            end
          elsif is_taxable_entrepreneur
            if rpo.dp_vat_type.eql?("include")
              get_include_vat_in_money_for_ap_partial rpo, "direct", gross_amount
            else
              get_vat_in_money_for_ap_partial rpo, "direct", gross_amount
            end
          end
          vat_type = if is_taxable_entrepreneur && rpo.purchase_order_id.present?
            rpo.po_vat_type
          elsif is_taxable_entrepreneur
            rpo.dp_vat_type
          end
          net_amount = if rpo.purchase_order_id.present?
            value_after_ppn_for_ap_partial rpo, "order", gross_amount
          else
            value_after_ppn_for_ap_partial rpo, "direct", gross_amount
          end
          self.total += net_amount
        end
      else
        account_payable_purchases.each do |account_payable_purchase|
          self.total += value_after_ppn_for_ap(account_payable_purchase.purchase)
        end
      end
    end
          
    def set_remaining_debt
      self.remaining_debt = total
    end
    
    def beginning_of_account_payable_creating_available
      BEGINNING_OF_AP_CREATINGS.select{ |x| x[1] == beginning_of_account_payable_creating }.first.first
    rescue
      errors.add(:beginning_of_account_payable_creating, "does not exist!")
    end
  end
