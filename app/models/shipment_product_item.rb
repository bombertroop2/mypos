class ShipmentProductItem < ApplicationRecord
  attr_accessor :order_booking_id, :order_booking_product_id

  audited associated_with: :shipment_product, on: [:create, :update]

  belongs_to :order_booking_product_item
  belongs_to :shipment_product
  validates :quantity, presence: true
  validates :quantity, numericality: {greater_than_or_equal_to: 0, only_integer: true}, if: proc { |spi| spi.quantity.present? }
    validate :item_available
    validate :quantity_available, if: proc{|spi| spi.quantity.present? && spi.quantity.is_a?(Numeric)}
  
      before_destroy :delete_tracks
      after_create :update_available_quantity
      after_destroy :update_available_quantity
      
      private
        
      def delete_tracks
        audits.destroy_all
      end
  
      def item_available
        @order_booking_product_item = if new_record?
          OrderBookingProductItem.joins(order_booking_product: :order_booking).
            where(id: order_booking_product_item_id, order_booking_product_id: order_booking_product_id).
            where(:"order_bookings.status" => "P").
            where(:"order_bookings.id" => order_booking_id).
            select(:quantity).first
        else
          OrderBookingProductItem.joins(order_booking_product: :order_booking).
            where(id: order_booking_product_item_id, order_booking_product_id: order_booking_product_id).
            where(:"order_bookings.status" => "F").
            where(:"order_bookings.id" => order_booking_id).
            select(:quantity).first
        end
        errors.add(:base, "Not able to deliver selected items") if @order_booking_product_item.blank?
      end
      
      def quantity_available        
        errors.add(:quantity, "cannot be greater than #{@order_booking_product_item.quantity}") if quantity > @order_booking_product_item.quantity
      end
      
      def update_available_quantity
        unless destroyed?
          order_booking_product_item.shipping = true
          order_booking_product_item.update_attribute :available_quantity, quantity
        else
          order_booking_product_item.cancel_shipment = true
          order_booking_product_item.old_available_quantity = order_booking_product_item.available_quantity
          order_booking_product_item.update_attribute :available_quantity, nil
        end
      end      
    end
