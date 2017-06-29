class ShipmentReceipt < ApplicationRecord
  attr_accessor :do_number, :ob_number, :creator

  audited on: [:create, :update]

  belongs_to :shipment
  has_many :shipment_receipt_products, dependent: :destroy
  
  accepts_nested_attributes_for :shipment_receipt_products
  
  validates :received_date, :shipment_id, presence: true
  validates :received_date, date: {before_or_equal_to: Proc.new { Date.current }, message: 'must be before or equal to today' }, if: proc {|shpmnt| shpmnt.received_date.present?}
    validates :received_date, date: {after_or_equal_to: proc {|shpmnt_rcpt| shpmnt_rcpt.shipment.delivery_date}, message: 'must be after or equal to delivery date of shipment' }, if: proc {|shpmnt| shpmnt.received_date.present? && shpmnt.shipment_id.present?}
      validate :shipment_available, if: proc{|shpmnt_rcpt| shpmnt_rcpt.shipment_id.present?}

        before_create :calculate_quantity, :update_received_date_on_shipment
        before_destroy :delete_tracks

        private
      
        def update_received_date_on_shipment
          shipment.update_attribute(:received_date, received_date)
        end
      
        def delete_tracks
          audits.destroy_all
        end
  
        def calculate_quantity
          self.quantity = shipment.quantity
        end
      
        def shipment_available
          if creator.has_non_spg_role? && Shipment.select("1 AS one").where(["received_date IS NULL AND id = ?", shipment_id]).blank?
            errors.add(:shipment_id, "does not exist!")
          elsif !creator.has_non_spg_role? && Shipment.joins(:order_booking).select("1 AS one").where(["received_date IS NULL AND shipments.id = ? AND order_bookings.destination_warehouse_id = ?", shipment_id, creator.sales_promotion_girl.warehouse_id]).blank?
            errors.add(:shipment_id, "does not exist!")
          end
        end
  
      end
