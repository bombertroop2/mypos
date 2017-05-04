class OrderBookingProductItem < ApplicationRecord
  attr_accessor :product_id, :origin_warehouse_id
  
  belongs_to :order_booking_product
  belongs_to :size
  belongs_to :color

  validates :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |dpd| dpd.quantity.present? }
    validate :item_available, on: :create

    private

    def item_available
      errors.add(:base, "Not able to order selected items") if StockDetail.joins(stock_product: :stock).
        where(size_id: size_id, color_id: color_id).
        where("stock_products.product_id = #{product_id}").
        where("stocks.warehouse_id = #{origin_warehouse_id}").
        select("1 AS one").blank?
    end
  end
