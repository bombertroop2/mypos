class ShipmentProductItem < ApplicationRecord
  attr_accessor :order_booking_id, :order_booking_product_id
  belongs_to :order_booking_product_item
  validate :item_available
  validates :quantity, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |spi| spi.quantity.present? }
    validate :quantity_available, if: proc{|spi| spi.quantity.present? && spi.quantity.is_a?(Numeric)}
  
      private
  
      def item_available
        @order_booking_product_item = OrderBookingProductItem.joins(order_booking_product: :order_booking).
          where(id: order_booking_product_item_id, order_booking_product_id: order_booking_product_id).
          where(:"order_bookings.status" => "P").
          where(:"order_bookings.id" => order_booking_id).
          select(:quantity).first
        errors.add(:base, "Not able to deliver selected items") if @order_booking_product_item.blank?
      end
      
      def quantity_available        
        errors.add(:quantity, "cannot be greater than #{@order_booking_product_item.quantity}") if quantity > @order_booking_product_item.quantity
      end

    end
