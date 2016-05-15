class PurchaseOrderDetail < ActiveRecord::Base
  belongs_to :purchase_order_product
  belongs_to :color
  belongs_to :size
  
  attr_accessor :is_updating_receiving_quantity, :is_updating_returning_quantity,
    :is_user_changing_cost, :is_user_changing_po_date

  validates :quantity, presence: true, on: :create
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |pod| pod.quantity.present? && !pod.is_updating_receiving_quantity && !pod.is_updating_returning_quantity }

    before_save :calculate_total_price, if: proc {|pod| !pod.is_user_changing_po_date && !pod.is_updating_receiving_quantity && !pod.is_updating_returning_quantity && !pod.is_user_changing_cost}
      before_validation :delete_record, if: proc {|pod| !pod.is_user_changing_po_date && !pod.is_updating_receiving_quantity && !pod.is_updating_returning_quantity && !pod.is_user_changing_cost}

        private
    
        def delete_record
          unless new_record?
            destroy if quantity.blank?
          end
        end

        def calculate_total_price
          self.total_unit_price = quantity * purchase_order_product.cost_list.cost if quantity.present?
        end

      end
