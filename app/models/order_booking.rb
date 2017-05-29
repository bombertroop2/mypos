class OrderBooking < ApplicationRecord
  belongs_to :origin_warehouse, class_name: "Warehouse", foreign_key: :origin_warehouse_id
  belongs_to :destination_warehouse, class_name: "Warehouse", foreign_key: :destination_warehouse_id
  belongs_to :creator, class_name: "User", foreign_key: :created_by
  has_many :order_booking_products, dependent: :destroy
  has_many :order_booking_product_items, through: :order_booking_products
  
  accepts_nested_attributes_for :order_booking_products, allow_destroy: true

  STATUSES = [
    ["O", "O"],
    ["P", "P"]
  ]
  
  validates :plan_date, :origin_warehouse_id, :destination_warehouse_id, presence: true
  validates :plan_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|po| po.plan_date_validable}
    validate :origin_warehouse_available, :destination_warehouse_available, :check_min_quantity_per_product
    validate :editable, on: :update
    
    before_create :generate_number, :set_status
    before_update :delete_old_products
    
    before_destroy :deletable
    
    def plan_date_validable
      return false if plan_date.blank?
      return true if new_record?
      return true if plan_date_changed? && persisted?
      return false
    end
    
    def self.printed
      where(status: "P")
    end

    private
    
    def delete_old_products
      if origin_warehouse_id_changed? && persisted?
        order_booking_products.select(:id, :order_booking_id, :quantity).destroy_all
      end
    end

    def editable
      errors.add(:base, "The record cannot be edited") unless status.eql?("O")
    end
    
    def deletable
      if !status.eql?("O") && !status.eql?("P")
        errors.add(:base, "The record cannot be deleted")
        throw :abort
      end 
    end
    
    
    def check_min_quantity_per_product
      if new_record?
        errors.add(:base, "Order booking must have at least one product") if order_booking_products.blank?
      elsif origin_warehouse_id_changed? && persisted?
        valid = false
        order_booking_products.each do |order_booking_product|
          if order_booking_product.new_record?
            valid = true
            break
          end
        end
        errors.add(:base, "Order booking must have at least one product") unless valid
      end
    end
    
    def origin_warehouse_available
      errors.add(:origin_warehouse_id, "does not exist!") if (new_record? || (origin_warehouse_id_changed? && persisted?)) && origin_warehouse_id.present? && Warehouse.central.where(id: origin_warehouse_id).select("1 AS one").blank?
    end

    def destination_warehouse_available
      errors.add(:destination_warehouse_id, "does not exist!") if (new_record? || (destination_warehouse_id_changed? && persisted?)) && destination_warehouse_id.present? && Warehouse.not_central.actived.where(id: destination_warehouse_id).select("1 AS one").blank?
    end
    
    def generate_number
      warehouse_code = Warehouse.select(:code).where(id: destination_warehouse_id).first.code
      today = Date.current
      current_month = today.month.to_s.rjust(2, '0')
      current_year = today.strftime("%y").rjust(2, '0')
      last_number = OrderBooking.where("number LIKE '#{warehouse_code}OB#{current_month}#{current_year}%'").select(:number).limit(1).order("id DESC").first.number rescue nil
      if last_number
        seq_number = last_number.split(last_number.scan(/#{warehouse_code}OB\d.{3}/).first).last.succ
        new_number = "#{warehouse_code}OB#{current_month}#{current_year}#{seq_number}"
      else
        new_number = "#{warehouse_code}OB#{current_month}#{current_year}00001"
      end
      self.number = new_number
    end
    
    def set_status
      self.status = "O"
    end

  end
