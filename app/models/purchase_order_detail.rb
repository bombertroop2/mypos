class PurchaseOrderDetail < ActiveRecord::Base
  belongs_to :product_detail
  belongs_to :purchase_order_product
  
  has_one :size, through: :product_detail
  has_one :color, through: :product_detail
  #  has_one :stock

  attr_accessor :size, :color, :product_id

  validates :quantity, :product_detail_id, presence: true
  validates :product_detail_id, uniqueness: {scope: :purchase_order_product_id}, if: proc { |pod| pod.product_detail_id.present? }
    validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |pod| pod.quantity.present? }
      validates :receiving_qty, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |pod| pod.receiving_qty.present? }

        before_save :calculate_total_price
#        before_save :reject_blank_quantity

        private

        def calculate_total_price
          self.total_unit_price = quantity * product_detail.product.cost if quantity.present?
        end

        def reject_blank_quantity
          return false if quantity.blank?
        end
      end
