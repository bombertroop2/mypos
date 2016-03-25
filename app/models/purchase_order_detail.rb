class PurchaseOrderDetail < ActiveRecord::Base
  belongs_to :purchase_order_product
  belongs_to :color
  belongs_to :size
  
  has_one :stock

  #  attr_accessor :size, :color, :product_id

  validates :quantity, presence: true, on: :create
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |pod| pod.quantity.present? }

    before_save :calculate_total_price
    before_validation :delete_record

    private
    
    def delete_record
      unless new_record?
        destroy if quantity.blank?
      end
    end

    def calculate_total_price
      self.total_unit_price = quantity * purchase_order_product.product.cost if quantity.present?
    end

  end
