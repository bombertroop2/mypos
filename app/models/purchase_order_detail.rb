class PurchaseOrderDetail < ApplicationRecord
  attr_accessor :is_updating_receiving_quantity, :is_updating_returning_quantity,
    :is_user_changing_cost, :is_user_changing_po_date, :product_id

  audited associated_with: :purchase_order_product, on: [:create, :update], except: [:receiving_qty, :returning_qty]

  belongs_to :purchase_order_product
  belongs_to :color
  belongs_to :size
  
  before_validation :prevent_system_creating_detail, on: :create

  validates :quantity, presence: true, on: :create
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |pod| pod.quantity.present? && !pod.is_updating_receiving_quantity && !pod.is_updating_returning_quantity }
    validate :size_available, :color_available, on: :create

    before_save :calculate_total_price, if: proc {|pod| !pod.is_user_changing_po_date && !pod.is_updating_receiving_quantity && !pod.is_updating_returning_quantity && !pod.is_user_changing_cost}
      before_validation :delete_record, if: proc {|pod| !pod.is_user_changing_po_date && !pod.is_updating_receiving_quantity && !pod.is_updating_returning_quantity && !pod.is_user_changing_cost}
        before_destroy :delete_tracks

        private

        def delete_tracks
          audits.destroy_all
        end

        def size_available
          errors.add(:size_id, "does not exist!") if Size.joins(product_details: :product).where(id: size_id).where("products.id = #{product_id}").select("1 AS one").blank?
        end

        def color_available
          errors.add(:color_id, "does not exist!") if Color.joins(product_colors: :product).where(id: color_id).where("products.id = #{product_id}").select("1 AS one").blank?
        end
        
        def prevent_system_creating_detail
          throw :abort if quantity.blank?
        end
    
        def delete_record
          unless new_record?
            destroy if quantity.blank?
          end
        end

        def calculate_total_price
          self.total_unit_price = quantity * purchase_order_product.cost_list.cost if quantity.present?
        end

      end
