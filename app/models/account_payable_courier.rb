class AccountPayableCourier < ApplicationRecord
  include AccountPayableCouriersHelper
  audited on: :create

  belongs_to :courier
  has_many :packing_lists
  has_many :account_payable_courier_payment_invoices, dependent: :restrict_with_error

  before_validation :strip_string_values

  validates :courier_id, :courier_invoice_number, :courier_invoice_date, presence: true
  validates :courier_invoice_number, uniqueness: true
  validates :total, numericality: {greater_than: 0}
  validates :courier_invoice_date, date: {before_or_equal_to: proc { Date.current }, message: 'must be before or equal to today' }, if: proc {|apc| apc.courier_invoice_date.present?}
    validate :courier_available, :check_min_packing_list_per_invoice, on: :create
    validate :transaction_open

    
    before_create :generate_number, :set_remaining_debt, :set_due_date, :set_value_added_tax_type
    before_destroy :delete_tracks, :remove_relationship
    
    accepts_nested_attributes_for :packing_lists

    INVOICE_STATUSES = [
      ["All", "All"],
      ["Paid off", "Paid off"],
      ["Not yet paid off", "Not yet paid off"]
    ]
    
    def packing_lists_attributes=(attributes)
      self.total = 0
      attributes.each do |key, val|
        packing_list = PackingList.
          select(:id, :number, :departure_date, :total_volume, :total_weight, "courier_prices.price AS courier_prc", "couriers.value_added_tax_type AS courier_vat_type", "courier_prices.courier_unit_id").
          joins(packing_list_items: :shipment, courier_price: [courier_unit: [courier_way: :courier]]).
          where(["packing_lists.account_payable_courier_id IS NULL AND packing_lists.departure_date <= ? AND couriers.id = ? AND couriers.status = 'External' AND shipments.received_date IS NOT NULL", courier_invoice_date, courier_id]).
          find(attributes[key]["id"])
        gross_amt = if packing_list.total_volume.present? && packing_list.total_volume > 0
          packing_list.total_volume * packing_list.courier_prc
        else
          packing_list.total_weight * packing_list.courier_prc
        end
        packing_list.attr_gross_amount = gross_amt
        vat_in_money = if packing_list.courier_vat_type.eql?("include")
          get_include_vat_in_money_for_ap_invoice_courier gross_amt
        else
          get_vat_in_money_for_ap_invoice_courier gross_amt
        end
        packing_list.attr_vat_in_money = vat_in_money
        net_amount = value_after_ppn_for_ap_invoice_courier packing_list, gross_amt
        packing_list.attr_net_amount = net_amount
        self.total += net_amount
        packing_lists << packing_list
      end
      super
    end

    private
    
    def remove_relationship
      packing_lists.select(:id, :account_payable_courier_id).each do |packing_list|
        packing_list.update_column(:account_payable_courier_id, nil)
      end
    end
    
    def set_value_added_tax_type      
      self.value_added_tax_type = @courier.value_added_tax_type
    end
    
    def set_due_date
      self.due_date = courier_invoice_date + @courier.terms_of_payment.days
    end
    
    def set_remaining_debt
      self.remaining_debt = total
    end
    
    def check_min_packing_list_per_invoice
      errors.add(:base, "Invoice must have at least one packing list") if packing_lists.blank?
    end
    
    def transaction_open
      errors.add(:base, "Sorry, you can't perform this transaction") if courier_invoice_date.present? && FiscalYear.joins(:fiscal_months).where(year: courier_invoice_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[courier_invoice_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
    end
    
    def delete_tracks
      audits.destroy_all
    end
  
    def strip_string_values
      self.courier_invoice_number = courier_invoice_number.strip
    end
                    
    def courier_available
      errors.add(:courier_id, "does not exist!") if courier_id.present? && (@courier = Courier.select(:terms_of_payment, :value_added_tax_type).where(id: courier_id, status: "External").first).blank?
    end
                                        
    def generate_number
      courier_invoice_date_month = courier_invoice_date.month.to_s.rjust(2, '0')
      courier_invoice_date_year = courier_invoice_date.strftime("%y").rjust(2, '0')
      existed_numbers = AccountPayableCourier.where("number LIKE 'INV#{courier.code}#{courier_invoice_date_month}#{courier_invoice_date_year}%'").select(:number).order(:number)
      if existed_numbers.blank?
        new_number = "INV#{courier.code}#{courier_invoice_date_month}#{courier_invoice_date_year}0001"
      else
        if existed_numbers.length == 1
          seq_number = existed_numbers[0].number.split("INV#{courier.code}#{courier_invoice_date_month}#{courier_invoice_date_year}").last
          if seq_number.to_i > 1
            new_number = "INV#{courier.code}#{courier_invoice_date_month}#{courier_invoice_date_year}0001"
          else
            new_number = "INV#{courier.code}#{courier_invoice_date_month}#{courier_invoice_date_year}#{seq_number.succ}"
          end
        else
          last_seq_number = ""
          existed_numbers.each_with_index do |existed_number, index|
            seq_number = existed_number.number.split("INV#{courier.code}#{courier_invoice_date_month}#{courier_invoice_date_year}").last
            if seq_number.to_i > 1 && index == 0
              new_number = "INV#{courier.code}#{courier_invoice_date_month}#{courier_invoice_date_year}0001"
              break                              
            elsif last_seq_number.eql?("")
              last_seq_number = seq_number
            elsif (seq_number.to_i - last_seq_number.to_i) > 1
              new_number = "INV#{courier.code}#{courier_invoice_date_month}#{courier_invoice_date_year}#{last_seq_number.succ}"
              break
            elsif index == existed_numbers.length - 1
              new_number = "INV#{courier.code}#{courier_invoice_date_month}#{courier_invoice_date_year}#{seq_number.succ}"
            else
              last_seq_number = seq_number
            end
          end
        end                        
      end
      self.number = new_number
    end          
  end
