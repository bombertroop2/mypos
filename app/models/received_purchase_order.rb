class ReceivedPurchaseOrder < ApplicationRecord
  audited on: :create

  belongs_to :purchase_order
  belongs_to :direct_purchase
  belongs_to :vendor
  has_many :received_purchase_order_products, dependent: :destroy


  accepts_nested_attributes_for :received_purchase_order_products, reject_if: :child_blank

  before_validation :strip_string_values, if: proc{|rpo| rpo.is_using_delivery_order.eql?("yes")}, on: :create

    validates :delivery_order_number, presence: true, unless: proc{|rpo| rpo.is_using_delivery_order.eql?("no")}, on: :create
      validate :minimum_receiving_item, on: :create, unless: proc {|rpo| rpo.is_it_direct_purchasing}
        validates :receiving_date, presence: true, on: :create, unless: proc {|rpo| rpo.is_it_direct_purchasing}
          validates :receiving_date, date: {after: proc {|rpo| rpo.purchase_order.purchase_order_date}, message: 'must be greater than purchase order date' }, on: :create, if: proc {|rpo| !rpo.is_it_direct_purchasing && rpo.receiving_date.present?}
            validates :receiving_date, date: {before_or_equal_to: proc { Date.current }, message: 'must be before or equal to today' }, on: :create, if: proc {|rpo| !rpo.is_it_direct_purchasing && rpo.receiving_date.present?}
              validates :purchase_order_id, presence: true, unless: proc {|rpo| rpo.is_it_direct_purchasing}
                validate :purchase_order_receivable, unless: proc{|rpo| rpo.is_it_direct_purchasing}
                  validates :vendor_id, presence: true, if: proc{|rpo| rpo.is_it_direct_purchasing}, on: :create
                    validate :transaction_open, if: proc{|rpo| !rpo.is_it_direct_purchasing && rpo.receiving_date.present?}

                      before_create :create_auto_do_number, if: proc{|rpo| rpo.is_using_delivery_order.eql?("no")}
                        before_create :calculate_total_quantity, unless: proc{|rpo| rpo.is_it_direct_purchasing}
                        after_create :purchase_order_journal, unless: proc{|rpo| rpo.is_it_direct_purchasing}

                          attr_accessor :is_it_direct_purchasing

                          private

                          def transaction_open
                            errors.add(:base, "Sorry, you can't perform this transaction") if FiscalYear.joins(:fiscal_months).where(year: receiving_date.year).where("fiscal_months.month = '#{Date::MONTHNAMES[receiving_date.month]}' AND fiscal_months.status = 'Close'").select("1 AS one").present?
                          end

                          def strip_string_values
                            self.delivery_order_number = delivery_order_number.strip
                          end

                          def purchase_order_receivable
                            errors.add(:base, "Not able to receive selected PO") unless PurchaseOrder.select("1 AS one").where("(status = 'Open' OR status = 'Partial') AND id = '#{purchase_order_id}' AND vendor_id = '#{vendor_id}'").present?
                          end

                          def calculate_total_quantity
                            self.quantity = 0
                            received_purchase_order_products.each do |received_purchase_order_product|
                              self.quantity += received_purchase_order_product.received_purchase_order_items.map(&:quantity).sum
                            end
                          end

                          def purchase_order_journal
                            coa = Coa.find_by_transaction_type("PO")
                            warehouse = self.purchase_order.warehouse_id
                            transaction_date = self.purchase_order.purchase_order_date
                            gross_price = self.purchase_order.get_gross_price
                            if self.purchase_order.first_discount.present? && self.purchase_order.second_discount.present?
                              first_discount = gross_price * self.purchase_order.first_discount/100
                              second_discount = (gross_price - first_discount) * self.purchase_order.second_discount/100
                              discount = first_discount + second_discount
                            elsif self.purchase_order.first_discount.present?
                              discount = gross_price * self.purchase_order.first_discount/100
                            else
                              discount = 0
                            end
                            if self.purchase_order.vendor.is_taxable_entrepreneur
                              if self.purchase_order.value_added_tax.eql?("include")
                                gross_after_discount = gross_price - discount
                                ppn = gross_after_discount * 10 / 100
                                nett = gross_after_discount
                              elsif self.purchase_order.value_added_tax.eql?("exclude")
                                gross_after_discount = gross_price - discount
                                ppn = gross_after_discount * 10 / 100
                                nett = gross_after_discount + ppn
                              end
                            else
                              p "==="
                              p gross_price
                              p "==="
                              gross_after_discount = gross_price - discount
                              ppn = 0
                              nett = gross_after_discount
                            end
                            if self.purchase_order.journal.present?
                              self.purchase_order.journal.update(
                                                  coa_id: coa.id,
                                                  gross: gross_price.to_f,
                                                  gross_after_discount: gross_after_discount.to_f,
                                                  discount: discount.to_f,
                                                  ppn: ppn.to_f,
                                                  nett: nett.to_f,
                                                  transaction_date: transaction_date,
                                                  activity: nil,
                                                  warehouse_id:warehouse
                                                )
                            else
                              journal = self.purchase_order.build_journal(
                                                  coa_id: coa.id,
                                                  gross: gross_price.to_f,
                                                  gross_after_discount: gross_after_discount.to_f,
                                                  discount: discount.to_f,
                                                  ppn: ppn.to_f,
                                                  nett: nett.to_f,
                                                  transaction_date: transaction_date,
                                                  activity: nil,
                                                  warehouse_id:warehouse
                                                )
                              journal.save
                            end
                          end

                          def create_auto_do_number
                            company_code = Company.pluck(:code).first
                            today = Date.current
                            current_month = today.month.to_s.rjust(2, '0')
                            current_year = today.strftime("%y").rjust(2, '0')
                            existed_numbers = ReceivedPurchaseOrder.where("delivery_order_number LIKE '#{company_code}#{(vendor.code)}#{current_month}#{current_year}%'").select(:delivery_order_number).order(:delivery_order_number)
                            if existed_numbers.blank?
                              new_number = "#{company_code}#{(vendor.code)}#{current_month}#{current_year}001"
                            else
                              if existed_numbers.length == 1
                                seq_number = existed_numbers[0].delivery_order_number.split("#{company_code}#{(vendor.code)}#{current_month}#{current_year}").last
                                if seq_number.to_i > 1
                                  new_number = "#{company_code}#{(vendor.code)}#{current_month}#{current_year}001"
                                else
                                  new_number = "#{company_code}#{(vendor.code)}#{current_month}#{current_year}#{seq_number.succ}"
                                end
                              else
                                last_seq_number = ""
                                existed_numbers.each_with_index do |existed_number, index|
                                  seq_number = existed_number.delivery_order_number.split("#{company_code}#{(vendor.code)}#{current_month}#{current_year}").last
                                  if seq_number.to_i > 1 && index == 0
                                    new_number = "#{company_code}#{(vendor.code)}#{current_month}#{current_year}001"
                                    break
                                  elsif last_seq_number.eql?("")
                                    last_seq_number = seq_number
                                  elsif (seq_number.to_i - last_seq_number.to_i) > 1
                                    new_number = "#{company_code}#{(vendor.code)}#{current_month}#{current_year}#{last_seq_number.succ}"
                                    break
                                  elsif index == existed_numbers.length - 1
                                    new_number = "#{company_code}#{(vendor.code)}#{current_month}#{current_year}#{seq_number.succ}"
                                  else
                                    last_seq_number = seq_number
                                  end
                                end
                              end
                            end

                            self.delivery_order_number = new_number
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

                        end
