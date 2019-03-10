class AccountsReceivableInvoice < ApplicationRecord
  attr_accessor :attr_shipment_quantity, :attr_gross_amount, :attr_vat_value, :attr_net_amount, :attr_customer_info, :attr_auto_create, :attr_discount_in_money
  audited on: :create

  INVOICE_STATUSES = [
    ["All", "All"],
    ["Paid off", "Paid off"],
    ["Not yet paid off", "Not yet paid off"]
  ]

  belongs_to :shipment
  has_many :shipment_product_items, through: :shipment
  
  before_validation :strip_string_values
  before_validation :set_total, :set_remaining_debt, :set_discount, unless: proc{|ari| ari.attr_auto_create}
  
    validates :shipment_id, presence: true
    validates :total, numericality: {greater_than: 0}
    validate :transaction_open, unless: proc{|ari| ari.attr_auto_create}
    
      before_create :generate_number, :set_due_date, unless: proc{|ari| ari.attr_auto_create}
        after_create :mark_shipment_invoiced, unless: proc{|ari| ari.attr_auto_create}
          after_create :send_email_to_customer
          before_destroy -> {transaction_open("delete")}
          after_destroy :unmark_invoiced_shipment, :delete_tracks

          private
          
          def set_discount
            self.discount = @shipment.customer_discount
          end
          
          def send_email_to_customer
            SendEmailJob.perform_later(self, "AR invoice")
          end
  
          def delete_tracks
            audits.destroy_all
          end
  
          def mark_shipment_invoiced
            shipment = Shipment.select(:id, :invoiced).find(shipment_id)
            shipment.update_column(:invoiced, true)
          end
  
          def unmark_invoiced_shipment
            @shipment.update_column(:invoiced, false)
          end
  
          def set_due_date
            self.due_date = @shipment.delivery_date + @shipment.customer_top.days
          end
  
          def set_total
            if shipment_id.present?
              @shipment = Shipment.
                select(:id, :delivery_date, :quantity, "customers.is_taxable_entrepreneur AS customer_is_taxable_entrepreneur", "customers.value_added_tax AS customer_vat_type", "customers.terms_of_payment AS customer_top", "customers.code AS customer_code", "customers.discount AS customer_discount").
                joins(order_booking: :customer).
                where(invoiced: false).
                where("order_bookings.customer_id IS NOT NULL").
                find(shipment_id)
              gross_amt = 0
              @shipment.shipment_product_items.select(:quantity, "price_lists.price").joins(:price_list).each do |spi|
                gross_amt += spi.quantity * spi.price
              end
              discount_in_money = gross_amt * (@shipment.customer_discount.to_f / 100)
              self.total = if @shipment.customer_is_taxable_entrepreneur
                if @shipment.customer_vat_type.eql?("include")
                  gross_amt - discount_in_money
                else
                  (gross_amt - discount_in_money) + (gross_amt - discount_in_money) * 0.1
                end
              else
                gross_amt - discount_in_money
              end
            end
          end

          def set_remaining_debt
            self.remaining_debt = total
          end
  
          def transaction_open(action = "not delete")
            if action.eql?("not delete")
              errors.add(:base, "Sorry, you can't perform this transaction") if FiscalYear.joins(:fiscal_months).where(year: @shipment.delivery_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[@shipment.delivery_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
            else
              @shipment = Shipment.select(:id, :invoiced, :delivery_date).find(shipment_id)
              if FiscalYear.joins(:fiscal_months).where(year: @shipment.delivery_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[@shipment.delivery_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                errors.add(:base, "Sorry, you can't perform this transaction")
                throw :abort if action.eql?("delete")
              end
            end
          end
  
          def strip_string_values
            self.note = note.strip
          end
  
          def generate_number
            two_digits_year = @shipment.delivery_date.strftime("%y").rjust(2, '0')
            pkp_code = @shipment.customer_is_taxable_entrepreneur ? "1" : "0"
            existed_numbers = AccountsReceivableInvoice.where("number LIKE '#{pkp_code}ARINV#{@shipment.customer_code}#{two_digits_year}%'").select(:number).order(:number)
            if existed_numbers.blank?
              new_number = "#{pkp_code}ARINV#{@shipment.customer_code}#{two_digits_year}00001"
            else
              if existed_numbers.length == 1
                seq_number = existed_numbers[0].number.split("#{pkp_code}ARINV#{@shipment.customer_code}#{two_digits_year}").last
                if seq_number.to_i > 1
                  new_number = "#{pkp_code}ARINV#{@shipment.customer_code}#{two_digits_year}00001"
                else
                  new_number = "#{pkp_code}ARINV#{@shipment.customer_code}#{two_digits_year}#{seq_number.succ}"
                end
              else
                last_seq_number = ""
                existed_numbers.each_with_index do |existed_number, index|
                  seq_number = existed_number.number.split("#{pkp_code}ARINV#{@shipment.customer_code}#{two_digits_year}").last
                  if seq_number.to_i > 1 && index == 0
                    new_number = "#{pkp_code}ARINV#{@shipment.customer_code}#{two_digits_year}00001"
                    break                              
                  elsif last_seq_number.eql?("")
                    last_seq_number = seq_number
                  elsif (seq_number.to_i - last_seq_number.to_i) > 1
                    new_number = "#{pkp_code}ARINV#{@shipment.customer_code}#{two_digits_year}#{last_seq_number.succ}"
                    break
                  elsif index == existed_numbers.length - 1
                    new_number = "#{pkp_code}ARINV#{@shipment.customer_code}#{two_digits_year}#{seq_number.succ}"
                  else
                    last_seq_number = seq_number
                  end
                end
              end                        
            end
            self.number = new_number
          end
        end
