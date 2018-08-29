class PurchaseReturn < ApplicationRecord
  attr_accessor :delivery_order_number, :direct_purchase_return

  audited on: :create

  has_many :allocated_return_items, dependent: :restrict_with_error
  has_many :purchase_return_products, dependent: :destroy
  belongs_to :purchase_order
  belongs_to :direct_purchase
  has_one :journal, :as => :transactionable

  validate :purchase_order_is_returnable, if: proc {|pr| pr.purchase_order_id.present? && !pr.direct_purchase_return}
    validate :direct_purchase_is_returnable, if: proc {|pr| pr.direct_purchase_id.present? && pr.direct_purchase_return}
      validates :purchase_order_id, presence: true, unless: proc{|pr| pr.direct_purchase_return}
        validates :delivery_order_number, :direct_purchase_id, presence: true, if: proc{|pr| pr.direct_purchase_return}
          validate :check_min_return_quantity, if: proc{|pr| pr.delivery_order_number.present? || pr.purchase_order_id.present?}

            before_create :generate_number
            after_create :purchase_return_journal

            accepts_nested_attributes_for :purchase_return_products, reject_if: :quantity_blank

            QUERY_OPERATORS = [
              ["AND", "AND"],
              ["OR", "OR"]
            ]

            def quantity_returned
              quantity = 0
              purchase_return_products.select(:total_quantity).each do |prp|
                quantity += prp.total_quantity
              end
              quantity
            end

            def get_gross_price
              if self.direct_purchase_id.present?
                costs = self.purchase_return_products.joins(direct_purchase_product: :cost_list).select("purchase_return_products.total_quantity, cost_lists.cost")
                gross_price = costs.collect{|x| x.cost.to_i * x.total_quantity }.sum
              elsif self.purchase_order_id.present?
                costs = self.purchase_return_products.joins(purchase_order_product: :cost_list).select("purchase_return_products.total_quantity, cost_lists.cost")
                gross_price = costs.collect{|x| x.cost.to_i * x.total_quantity }.sum
              end
              return gross_price
            end

            private

            def purchase_return_journal
              coa = Coa.find_by_transaction_type("PR")
              gross_price = self.get_gross_price
              transaction_date = self.created_at.to_date
              if self.direct_purchase_id.present?
                warehouse = self.direct_purchase.warehouse_id
                if self.direct_purchase.first_discount.present? && self.direct_purchase.second_discount.present?
                  first_discount = gross_price * self.direct_purchase.first_discount/100
                  second_discount = (gross_price - first_discount) * self.direct_purchase.second_discount/100
                  discount = first_discount + second_discount
                elsif self.direct_purchase.first_discount.present?
                  discount = gross_price * self.direct_purchase.first_discount/100
                else
                  discount = 0
                end
                if self.direct_purchase.is_taxable_entrepreneur
                  if self.direct_purchase.vat_type.eql?("include")
                    gross_after_discount = gross_price - discount
                    ppn = gross_after_discount * 10 / 100
                    nett = gross_after_discount
                  elsif self.direct_purchase.vat_type.eql?("exclude")
                    gross_after_discount = gross_price - discount
                    ppn = gross_after_discount * 10 / 100
                    nett = gross_after_discount + ppn
                  end
                else
                  gross_after_discount = gross_price - discount
                  ppn = 0
                  nett = gross_after_discount
                end
              elsif self.purchase_order_id.present?
                warehouse = self.purchase_order.warehouse_id
                if self.purchase_order.first_discount.present? && self.purchase_order.second_discount.present?
                  first_discount = gross_price * self.purchase_order.first_discount/100
                  second_discount = (gross_price - first_discount) * self.purchase_order.second_discount/100
                  discount = first_discount + second_discount
                elsif self.purchase_order.first_discount.present?
                  discount = gross_price * self.purchase_order.first_discount/100
                else
                  discount = 0
                end
                 if self.purchase_order.is_taxable_entrepreneur
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
                  gross_after_discount = gross_price - discount
                  ppn = 0
                  nett = gross_after_discount
                end
              end
              journal = self.build_journal(
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

            def quantity_blank(attributed)
              return false if attributed[:purchase_return_items_attributes].select{|key, hash| !hash["quantity"].strip.eql?("")}.present?
              return true
            end

            def purchase_order_is_returnable
              errors.add(:purchase_order_id, "does not exist!") if PurchaseOrder.where(["status != 'Open' AND id = ?", purchase_order_id]).select("1 AS one").blank?
            end

            def direct_purchase_is_returnable
              errors.add(:delivery_order_number, "does not exist!") if DirectPurchase.where(["id = ?", direct_purchase_id]).select("1 AS one").blank?
            end

            def check_min_return_quantity
              valid = false
              purchase_return_products.each do |purchase_return_product|
                if purchase_return_product.purchase_return_items.present?
                  valid = true
                  break
                end
              end
              errors.add(:base, "Purchase return must have at least one return item") unless valid
            end

            def generate_number
              today = Date.current
              current_month = today.month.to_s.rjust(2, '0')
              current_year = today.strftime("%y").rjust(2, '0')
              vendor_code = if direct_purchase_return
                Vendor.joins(:direct_purchases).select(:code).where(["direct_purchases.id = ?", direct_purchase_id]).first.code
              else
                Vendor.joins(:purchase_orders).select(:code).where(["purchase_orders.id = ?", purchase_order_id]).first.code
              end

              existed_numbers = PurchaseReturn.where("number LIKE 'PRR#{vendor_code}#{current_month}#{current_year}%'").select(:number).order(:number)
              if existed_numbers.blank?
                new_number = "PRR#{vendor_code}#{current_month}#{current_year}0001"
              else
                if existed_numbers.length == 1
                  seq_number = existed_numbers[0].number.split("PRR#{vendor_code}#{current_month}#{current_year}").last
                  if seq_number.to_i > 1
                    new_number = "PRR#{vendor_code}#{current_month}#{current_year}0001"
                  else
                    new_number = "PRR#{vendor_code}#{current_month}#{current_year}#{seq_number.succ}"
                  end
                else
                  last_seq_number = ""
                  existed_numbers.each_with_index do |existed_number, index|
                    seq_number = existed_number.number.split("PRR#{vendor_code}#{current_month}#{current_year}").last
                    if seq_number.to_i > 1 && index == 0
                      new_number = "PRR#{vendor_code}#{current_month}#{current_year}0001"
                      break
                    elsif last_seq_number.eql?("")
                      last_seq_number = seq_number
                    elsif (seq_number.to_i - last_seq_number.to_i) > 1
                      new_number = "PRR#{vendor_code}#{current_month}#{current_year}#{last_seq_number.succ}"
                      break
                    elsif index == existed_numbers.length - 1
                      new_number = "PRR#{vendor_code}#{current_month}#{current_year}#{seq_number.succ}"
                    else
                      last_seq_number = seq_number
                    end
                  end
                end
              end

              self.number = new_number
            end


          end
