class CostList < ApplicationRecord
  belongs_to :product

  has_many :purchase_order_products#, dependent: :restrict_with_error
  has_many :direct_purchase_products
  has_one :created_purchase_order, -> {select("1 AS one").joins(:purchase_order).where("purchase_orders.status <> 'Deleted'")}, class_name: "PurchaseOrderProduct"
  has_one :received_purchase_order, -> {select("1 AS one").joins(:purchase_order).where("purchase_orders.status <> 'Deleted' AND purchase_orders.status <> 'Open'")}, class_name: "PurchaseOrderProduct"
  has_one :direct_purchase_product, -> {select("1 AS one")}, class_name: "DirectPurchaseProduct"
  
  before_validation :set_effective_date, if: proc{|cost_list| cost_list.is_user_creating_product}

    validates :cost, :effective_date, presence: true
    validates :product_id, presence: true, unless: proc{|cost_list| cost_list.is_user_creating_product}
      validates :cost, numericality: true, if: proc { |cost_list| cost_list.cost.present? }
        validates :cost, numericality: {greater_than: 0}, if: proc { |cost_list| cost_list.cost.is_a?(Numeric) }
          validates :effective_date, date: {after_or_equal_to: Proc.new { Date.current }, message: 'must be after or equal to today' }, if: proc {|cost_list| cost_list.effective_date.present? && cost_list.effective_date_changed?}
            validates :effective_date, uniqueness: {scope: :product_id}, if: proc {|cost_list| cost_list.effective_date.present?}
              validate :fields_not_changed
  
              attr_accessor :is_user_creating_product, :user_is_deleting_from_child
          
              before_destroy :prevent_user_delete_last_record, if: proc {|cost_list| cost_list.user_is_deleting_from_child}
                before_destroy :prevent_delete_if_purchase_order_created, :prevent_delete_if_direct_purchase_created
                #            before_update :update_total_unit_cost_of_purchase_order, if: proc {|cost_list| cost_list.cost_changed?}
                #              after_create :update_purchase_order_cost              
                after_destroy :delete_prices
              
                default_scope { order(effective_date: :desc) }
          
                private
  
                def delete_prices
                  product_details = product.product_details.select(:id)
                  product_details.each do |product_detail|
                    product_detail.price_lists.select(:id).where(effective_date: effective_date).destroy_all
                    if product_detail.price_lists.count(:id) == 0
                      product_detail.destroy
                    end
                  end
                end
              
                def set_effective_date
                  self.effective_date = Date.current
                end
  
                def fields_not_changed
                  errors.add(:effective_date, "change is not allowed!") if effective_date_changed? && persisted? && (created_purchase_order.present? || direct_purchase_product.present?)
                  errors.add(:cost, "change is not allowed!") if cost_changed? && persisted? && (created_purchase_order.present? || direct_purchase_product.present?)
                  errors.add(:product_id, "change is not allowed!") if product_id_changed? && persisted? && (created_purchase_order.present? || direct_purchase_product.present?)
                end

                def prevent_user_delete_last_record
                  if product.cost_count.eql?(1)
                    errors.add(:base, "Sorry, you can't delete a record")
                    throw :abort
                  end
                end

                def prevent_delete_if_purchase_order_created   
                  if created_purchase_order
                    errors.add(:base, "Cannot delete record with purchase order")
                    throw :abort
                  end
                end

                def prevent_delete_if_direct_purchase_created   
                  if direct_purchase_product
                    errors.add(:base, "Cannot delete record")
                    throw :abort
                  end
                end

              end
