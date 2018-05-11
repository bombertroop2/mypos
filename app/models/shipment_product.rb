class ShipmentProduct < ApplicationRecord
  attr_accessor :order_booking_id
  audited associated_with: :shipment, on: [:create, :update]
  has_associated_audits

  belongs_to :order_booking_product
  belongs_to :shipment

  has_many :shipment_product_items, dependent: :destroy

  accepts_nested_attributes_for :shipment_product_items#, reject_if: proc { |attributes| attributes[:quantity].blank? }
  
  validate :product_available
  
  before_destroy :delete_tracks

  private
  
  def delete_tracks
    audits.destroy_all
  end
  
  def product_available
    if new_record? && OrderBookingProduct.joins(order_booking: [:origin_warehouse, :destination_warehouse]).
        where(id: order_booking_product_id, order_booking_id: order_booking_id).
        where(:"order_bookings.status" => "P").
        where(["warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true]).
        select("1 AS one").blank?
      errors.add(:base, "Some products do not exist!")
    elsif !new_record? && OrderBookingProduct.joins(order_booking: [:origin_warehouse, :destination_warehouse]).
        where(id: order_booking_product_id, order_booking_id: order_booking_id).
        where(:"order_bookings.status" => "F").
        where(["warehouses.is_active = ? AND destination_warehouses_order_bookings.is_active = ?", true, true]).
        select("1 AS one").blank?
      errors.add(:base, "Some products do not exist!")
    end
  end
end
