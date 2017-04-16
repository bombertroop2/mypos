class PurchaseReturn < ApplicationRecord
  attr_accessor :delivery_order_number, :direct_purchase_return
  
  has_many :allocated_return_items, dependent: :restrict_with_error
  has_many :purchase_return_products, dependent: :destroy
  belongs_to :purchase_order
  belongs_to :direct_purchase
  belongs_to :creator, class_name: "User", foreign_key: :created_by
  
  validate :purchase_order_is_returnable, if: proc {|pr| pr.purchase_order_id.present? && !pr.direct_purchase_return}
    validates :purchase_order_id, presence: true, unless: proc{|pr| pr.direct_purchase_return}
      validates :delivery_order_number, presence: true, if: proc{|pr| pr.direct_purchase_return}
        validate :check_min_return_quantity, if: proc{|pr| pr.delivery_order_number.present? || pr.purchase_order_id.present?}
  
          before_create :generate_number
  
          accepts_nested_attributes_for :purchase_return_products, reject_if: :quantity_blank

          def quantity_returned
            quantity = 0
            purchase_return_products.select(:total_quantity).each do |prp|
              quantity += prp.total_quantity
            end
            quantity
          end
    
          private
      
          def quantity_blank(attributed)
            return false if attributed[:purchase_return_items_attributes].select{|key, hash| !hash["quantity"].strip.eql?("")}.present?
            return true
          end
  
          def purchase_order_is_returnable
            errors.add(:purchase_order_id, "return is not allowed") if PurchaseOrder.where(["status != 'Open' AND status != 'Deleted' AND id = ?", purchase_order_id]).select("1 AS one").blank?
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
            today = Date.today
            current_month = today.month.to_s.rjust(2, '0')
            current_year = today.strftime("%y").rjust(2, '0')
            vendor_code = if direct_purchase_return
              Vendor.joins(:direct_purchases).select(:code).where(["direct_purchases.id = ?", direct_purchase_id]).first.code
            else
              Vendor.joins(:purchase_orders).select(:code).where(["purchase_orders.id = ?", purchase_order_id]).first.code
            end

            last_pr = PurchaseReturn.where("number LIKE 'PRR#{vendor_code}#{current_month}#{current_year}%'").select(:number).last

            if last_pr
              seq_number = last_pr.number.split(last_pr.number.scan(/PRR#{vendor_code}\d.{3}/).first).last.succ
              new_pr_number = "PRR#{vendor_code}#{current_month}#{current_year}#{seq_number}"
            else
              new_pr_number = "PRR#{vendor_code}#{current_month}#{current_year}0001"
            end
            self.number = new_pr_number
          end
          

        end
