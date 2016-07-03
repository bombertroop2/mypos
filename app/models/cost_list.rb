class CostList < ApplicationRecord
  belongs_to :product

  has_many :purchase_order_products#, dependent: :restrict_with_error
  has_one :created_purchase_order, -> {select("1 AS one").joins(:purchase_order).where("purchase_orders.status <> 'Deleted'")}, class_name: "PurchaseOrderProduct"
  has_one :received_purchase_order, -> {select("1 AS one").joins(:purchase_order).where("purchase_orders.status <> 'Deleted' AND purchase_orders.status <> 'Open'")}, class_name: "PurchaseOrderProduct"

  validates :cost, :effective_date, presence: true
  validates :product_id, presence: true, unless: proc{|cost_list| cost_list.is_user_creating_product}
    validates :cost, numericality: true, if: proc { |cost_list| cost_list.cost.present? }
      validates :cost, numericality: {greater_than: 0}, if: proc { |cost_list| cost_list.cost.is_a?(Numeric) }
        validates :effective_date, date: {after_or_equal_to: Proc.new { Date.today }, message: 'must be after or equal to today' }, if: proc {|cost_list| cost_list.effective_date.present? && cost_list.effective_date_changed?}
          validate :fields_not_changed
  
          attr_accessor :is_user_creating_product, :user_is_deleting_from_child
          
          before_destroy :prevent_user_delete_last_record, if: proc {|cost_list| cost_list.user_is_deleting_from_child}
            before_destroy :prevent_delete_if_purchase_order_created
            before_update :update_total_unit_cost_of_purchase_order, if: proc {|cost_list| cost_list.cost_changed?}
              after_create :update_purchase_order_cost              
              
          
              private
              
              def update_purchase_order_cost
                purchase_orders = PurchaseOrder.open_purchase_order_filter_by_po_date(effective_date)
                purchase_orders.each do |purchase_order|
                  purchase_order_products = purchase_order.purchase_order_products.joins(:cost_list).select("purchase_order_products.id, cost_list_id, effective_date, purchase_order_products.product_id as product_id")
                  total_order_value = 0
                  purchase_order_products.each do |purchase_order_product|
                    if purchase_order_product.effective_date.to_date < effective_date && product_id.eql?(purchase_order_product.product_id)
                      purchase_order_product.is_user_adding_new_cost = true
                      purchase_order_product.cost_list_id = id
                      if purchase_order_product.save
                        total_unit_cost = purchase_order_product.purchase_order_details.sum(:total_unit_price)
                        total_order_value += total_unit_cost
                      end
                    else
                      total_unit_cost = purchase_order_product.purchase_order_details.sum(:total_unit_price)
                      total_order_value += total_unit_cost
                    end
                  end
                  
                  price_discount = purchase_order.price_discount
                  if (price_discount.present? && price_discount <= total_order_value) || price_discount.blank?
                    purchase_order.is_user_changing_cost = true
                    purchase_order.order_value = total_order_value
                    purchase_order.save
                  else
                    raise "add is not allowed, because discount is greater than total order value"
                  end
                end
              end
            
              def update_total_unit_cost_of_purchase_order
                purchase_order_products = self.purchase_order_products.joins(:purchase_order).select("purchase_order_products.id, purchase_orders.id as purchase_orders_id")
                if purchase_order_products.present?
                  purchase_order_products.each do |purchase_order_product|
                    purchase_order_details = purchase_order_product.purchase_order_details.select(:total_unit_price, :quantity, :id)
                    
                    # --start-- update order value di purchase order
                    total_quantity = purchase_order_details.map(&:quantity).compact.sum
                    total_product_value = cost * total_quantity
                    purchase_order = PurchaseOrder.where(id: purchase_order_product.purchase_orders_id).select("order_value, price_discount, id").first
                    other_purchase_order_products = purchase_order.purchase_order_products.where("cost_list_id <> #{id}").select(:id, :cost_list_id)
                    total_product_value_of_other_product = 0
                    other_purchase_order_products.each do |opop|
                      total_quantity = opop.purchase_order_details.sum(:quantity)
                      total_product_value_of_other_product += opop.cost_list.cost * total_quantity
                    end
                    
                    new_total_order_value = total_product_value_of_other_product + total_product_value
                    price_discount = purchase_order.price_discount
                    if (price_discount.present? && price_discount <= new_total_order_value) || price_discount.blank?
                      purchase_order.is_user_changing_cost = true
                      purchase_order.order_value = new_total_order_value
                      if purchase_order.save
                        purchase_order_details.each do |purchase_order_detail|
                          purchase_order_detail.is_user_changing_cost = true
                          purchase_order_detail.total_unit_price = purchase_order_detail.quantity * cost
                          purchase_order_detail.save
                        end
                      end
                    else
                      errors.add(:cost, "change is not allowed, because discount is greater than total order value")
                      return false
                    end
                  end
                end
              end
            
              def fields_not_changed
                errors.add(:effective_date, "change is not allowed!") if effective_date_changed? && persisted? && created_purchase_order.present?
                errors.add(:cost, "change is not allowed!") if cost_changed? && persisted? && received_purchase_order.present?
                errors.add(:product_id, "change is not allowed!") if product_id_changed? && persisted? && created_purchase_order.present?
              end
          
              def prevent_user_delete_last_record
                if product.cost_count.eql?(1)
                  errors.add(:base, "Sorry, you can't delete a record")
                  return false
                end
              end
            
              def prevent_delete_if_purchase_order_created   
                if created_purchase_order
                  errors.add(:base, "Cannot delete record with purchase order")
                  return false
                end
              end
          
            end
