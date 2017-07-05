class Shipment < ApplicationRecord
  audited on: [:create, :update]
  has_associated_audits

  attr_accessor :order_booking_number
  
  belongs_to :order_booking
  belongs_to :courier
  
  has_many :shipment_products, dependent: :destroy

  accepts_nested_attributes_for :shipment_products, allow_destroy: true#, reject_if: :child_blank
  
  validates :delivery_date, :courier_id, :order_booking_id, presence: true
  validates :delivery_date, date: {after_or_equal_to: proc {|shpmnt| shpmnt.order_booking.created_at.to_date}, message: 'must be after or equal to creation date of order booking' }, if: proc {|shpmnt| shpmnt.delivery_date.present? && shpmnt.order_booking_id.present?}
    validates :delivery_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|shpmnt| shpmnt.delivery_date.present?}
      validate :courier_available, :order_booking_available#, :check_min_quantity
      validate :editable, on: :update
      validate :order_booking_not_changed, on: :update, if: proc{|shipment| shipment.order_booking_id_changed?}

        before_create :generate_do_number
        after_create :finish_ob, :notify_store
        before_destroy :deletable, :delete_tracks
        after_destroy :set_ob_status_to_p


        private
      
        def order_booking_not_changed        
          errors.add(:order_booking_id, "cannot be changed")
        end
      
        def editable
          errors.add(:base, "The record cannot be edited") if received_date.present?
        end
      
        def notify_store
          notification = Notification.new(event: "New Notification", body: "Shipment #{delivery_order_number} will arrive soon")
          order_booking.destination_warehouse.sales_promotion_girls.joins(:user).select("users.id AS user_id").each do |sales_promotion_girl|
            notification.recipients.build user_id: sales_promotion_girl.user_id, notified: false, read: false
          end
          notification.save
        end
      
        def delete_tracks
          audits.destroy_all
        end
  
        def set_ob_status_to_p
          order_booking.without_auditing do
            order_booking.update_attribute :status, "P"
          end
        end
      
        def deletable
          if received_date.present?
            errors.add(:base, "The record cannot be deleted")
            throw :abort
          end 
        end
    
        def courier_available
          errors.add(:courier_id, "does not exist!") if (new_record? || (courier_id_changed? && persisted?)) && courier_id.present? && Courier.where(id: courier_id).select("1 AS one").blank?
        end
    
        def order_booking_available
          errors.add(:order_booking_id, "does not exist!") if (new_record? || (order_booking_id_changed? && persisted?)) && order_booking_id.present? && OrderBooking.where(id: order_booking_id).printed.select("1 AS one").blank?
        end
  
        def child_blank(attributed)
          attributed[:shipment_product_items_attributes].each do |key, value| 
            return false if value[:quantity].present?
          end
      
          return true
        end
    
        #      def check_min_quantity
        #        if new_record?
        #          errors.add(:base, "Shipment must have at least one piece of product") if shipment_products.blank?
        #        end
        #      end
    
        def generate_do_number
          warehouse_code = Warehouse.select(:code).where(id: order_booking.destination_warehouse_id).first.code
          today = Date.current
          current_month = today.month.to_s.rjust(2, '0')
          current_year = today.strftime("%y").rjust(2, '0')
          existed_numbers = Shipment.where("delivery_order_number LIKE '#{warehouse_code}SJ#{current_month}#{current_year}%'").select(:delivery_order_number).order(:delivery_order_number)
          if existed_numbers.blank?
            new_number = "#{warehouse_code}SJ#{current_month}#{current_year}0001"
          else
            if existed_numbers.length == 1
              seq_number = existed_numbers[0].delivery_order_number.split("#{warehouse_code}SJ#{current_month}#{current_year}").last
              if seq_number.to_i > 1
                new_number = "#{warehouse_code}SJ#{current_month}#{current_year}0001"
              else
                new_number = "#{warehouse_code}SJ#{current_month}#{current_year}#{seq_number.succ}"
              end
            else
              last_seq_number = ""
              existed_numbers.each_with_index do |existed_number, index|
                seq_number = existed_number.delivery_order_number.split("#{warehouse_code}SJ#{current_month}#{current_year}").last
                if seq_number.to_i > 1 && index == 0
                  new_number = "#{warehouse_code}SJ#{current_month}#{current_year}0001"
                  break                              
                elsif last_seq_number.eql?("")
                  last_seq_number = seq_number
                elsif (seq_number.to_i - last_seq_number.to_i) > 1
                  new_number = "#{warehouse_code}SJ#{current_month}#{current_year}#{last_seq_number.succ}"
                  break
                elsif index == existed_numbers.length - 1
                  new_number = "#{warehouse_code}SJ#{current_month}#{current_year}#{seq_number.succ}"
                else
                  last_seq_number = seq_number
                end
              end
            end                        
          end

          self.delivery_order_number = new_number
        end
    
        def finish_ob
          order_booking.without_auditing do
            order_booking.update_attribute :status, "F"
          end
        end
      end
