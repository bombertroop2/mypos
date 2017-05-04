class OrderBookingProduct < ApplicationRecord
  attr_accessor :product_code, :product_name, :origin_warehouse_id
  
  belongs_to :order_booking
  belongs_to :product
  
  has_many :order_booking_product_items, dependent: :destroy
  
  accepts_nested_attributes_for :order_booking_product_items, reject_if: proc {|attributes| attributes[:quantity].blank?}
  
  validates :product_id, presence: true
  validate :product_available, if: proc{|obp| obp.product_id.present?}
    
    before_create :calculate_quantity
  
    private
  
    def product_available
      errors.add(:base, "Some products do not exist!") if Product.joins(stock_products: :stock).
        where(id: product_id).
        where("stocks.warehouse_id = #{origin_warehouse_id}").
        select("1 AS one").blank?
    end
    
    def calculate_quantity
      quantity = 0
      order_booking_product_items.each do |order_booking_product_item|
        quantity += order_booking_product_item.quantity
      end
      self.quantity = quantity
    end

  end
