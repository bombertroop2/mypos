class ShipmentProduct < ApplicationRecord
  attr_accessor :order_booking_id
  belongs_to :order_booking_product

  has_many :shipment_product_items, dependent: :destroy

  accepts_nested_attributes_for :shipment_product_items#, reject_if: proc { |attributes| attributes[:quantity].blank? }
  
  validate :product_available
  
  private
  
  def product_available
    errors.add(:base, "Some products do not exist!") if OrderBookingProduct.joins(:order_booking).
      where(id: order_booking_product_id, order_booking_id: order_booking_id).
      where(:"order_bookings.status" => "P").
      select("1 AS one").blank?
  end
end
