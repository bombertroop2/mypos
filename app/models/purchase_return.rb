class PurchaseReturn < ApplicationRecord
  attr_accessor :delivery_order_number, :direct_purchase_return, :attr_purchase_return_number, :attr_purchase_return_net_amount
  
  audited on: :create

  has_many :allocated_return_items, dependent: :restrict_with_error
  has_many :purchase_return_products, dependent: :destroy
  belongs_to :purchase_order
  belongs_to :direct_purchase
    
  validate :purchase_order_is_returnable, if: proc {|pr| pr.purchase_order_id.present? && !pr.direct_purchase_return}
    validate :direct_purchase_is_returnable, if: proc {|pr| pr.direct_purchase_id.present? && pr.direct_purchase_return}
      validates :purchase_order_id, presence: true, unless: proc{|pr| pr.direct_purchase_return}
        validates :delivery_order_number, :direct_purchase_id, presence: true, if: proc{|pr| pr.direct_purchase_return}
          validate :check_min_return_quantity, if: proc{|pr| pr.delivery_order_number.present? || pr.purchase_order_id.present?}
  
            before_create :generate_number, :set_attr_purchase_return_number, :calculate_net_amount
  
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
    
            private
            
            def calculate_net_amount
              self.attr_purchase_return_net_amount = if purchase_order_id.present?
                # hitung gross return amount
                total_return_value = 0
                purchase_return_products.each do |purchase_return_product|
                  purchase_order_product = @purchase_doc.purchase_order_products.select{|pop| pop.id == purchase_return_product.purchase_order_product_id}.first
                  product_cost = purchase_order_product.cost_list.cost
                  purchase_return_product.purchase_return_items.each do |purchase_return_item|
                    total_return_value += purchase_return_item.quantity * product_cost
                  end
                end
                
                # potong gross return amount dengan diskon
                value_after_first_discount = total_return_value - total_return_value * (@purchase_doc.first_discount.to_f / 100)
                value_after_second_discount = if @purchase_doc.is_additional_disc_from_net
                  value_after_first_discount - value_after_first_discount * (@purchase_doc.second_discount.to_f / 100)
                elsif @purchase_doc.second_discount.present?
                  total_return_value - total_return_value * ((@purchase_doc.first_discount.to_f + @purchase_doc.second_discount.to_f) / 100)
                end
                value_after_discount = value_after_second_discount || value_after_first_discount
                
                # hitung net amount
                if @purchase_doc.is_taxable_entrepreneur                
                  if @purchase_doc.value_added_tax.eql?("exclude")
                    value_after_discount + value_after_discount * 0.1
                  else
                    value_after_discount                    
                  end
                else
                  value_after_discount                    
                end
              else
                # hitung gross return amount
                total_return_value = 0
                purchase_return_products.each do |purchase_return_product|
                  direct_purchase_product = @purchase_doc.direct_purchase_products.select{|dpp| dpp.id == purchase_return_product.direct_purchase_product_id}.first
                  product_cost = direct_purchase_product.cost_list.cost
                  purchase_return_product.purchase_return_items.each do |purchase_return_item|
                    total_return_value += purchase_return_item.quantity * product_cost
                  end
                end
                
                # potong gross return amount dengan diskon
                value_after_first_discount = total_return_value - total_return_value * (@purchase_doc.first_discount.to_f / 100)
                value_after_second_discount = if @purchase_doc.is_additional_disc_from_net
                  value_after_first_discount - value_after_first_discount * (@purchase_doc.second_discount.to_f / 100)
                elsif @purchase_doc.second_discount.present?
                  total_return_value - total_return_value * ((@purchase_doc.first_discount.to_f + @purchase_doc.second_discount.to_f) / 100)
                end
                value_after_discount = value_after_second_discount || value_after_first_discount
                
                # hitung net amount
                if @purchase_doc.is_taxable_entrepreneur                
                  if @purchase_doc.vat_type.eql?("exclude")
                    value_after_discount + value_after_discount * 0.1
                  else
                    value_after_discount                    
                  end
                else
                  value_after_discount                    
                end
              end
            end
            
            def set_attr_purchase_return_number
              self.attr_purchase_return_number = if purchase_order_id.present?
                @purchase_doc.number
              else
                @purchase_doc.delivery_order_number
              end              
            end
      
            def quantity_blank(attributed)
              return false if attributed[:purchase_return_items_attributes].select{|key, hash| !hash["quantity"].strip.eql?("")}.present?
              return true
            end
  
            def purchase_order_is_returnable
              errors.add(:purchase_order_id, "does not exist!") if (@purchase_doc = PurchaseOrder.where(["status != 'Open' AND id = ?", purchase_order_id]).select(:id, :number, :value_added_tax, :is_taxable_entrepreneur, :first_discount, :second_discount, :is_additional_disc_from_net).includes(purchase_order_products: :cost_list).first).blank?
            end

            def direct_purchase_is_returnable
              errors.add(:delivery_order_number, "does not exist!") if (@purchase_doc = DirectPurchase.where(["direct_purchases.id = ?", direct_purchase_id]).select(:id, :vat_type, :is_taxable_entrepreneur, :first_discount, :second_discount, :is_additional_disc_from_net, "received_purchase_orders.delivery_order_number").joins(:received_purchase_order).includes(direct_purchase_products: :cost_list).first).blank?
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
