class OrderBooking < ApplicationRecord
  belongs_to :origin_warehouse
  belongs_to :destination_warehouse
  has_many :order_booking_products, dependent: :destroy
  has_many :order_booking_product_items, through: :order_booking_products
  
  accepts_nested_attributes_for :order_booking_products

  STATUSES = [
    ["O", "O"],
    ["P", "P"]
  ]
  
  validates :plan_date, :origin_warehouse_id, :destination_warehouse_id, presence: true
  validates :plan_date, date: {after_or_equal_to: proc { Date.current }, message: 'must be after or equal to today' }, if: proc {|po| po.plan_date.present?}
    validate :origin_warehouse_available, :destination_warehouse_available, :check_min_quantity_per_product
    
    before_create :calculate_quantity, :generate_number, :set_status
    
    private
    
    def calculate_quantity
      quantity = 0
      order_booking_products.each do |order_booking_product|
        order_booking_product.order_booking_product_items.each do |order_booking_product_item|
          quantity += order_booking_product_item.quantity
        end
      end
      self.quantity = quantity
    end
    
    def check_min_quantity_per_product
      valid = false
      order_booking_products.each do |order_booking_product|
        if order_booking_product.order_booking_product_items.present?
          valid = true          
        else
          valid = false
          break
        end
      end      
      errors.add(:base, "Order booking must have at least one product") if order_booking_products.blank?
      errors.add(:base, "Order booking must have at least one quantity per product") if !valid && order_booking_products.present?
    end
    
    def origin_warehouse_available
      errors.add(:origin_warehouse_id, "does not exist!") if origin_warehouse_id.present? && Warehouse.central.where(id: origin_warehouse_id).select("1 AS one").blank?
    end

    def destination_warehouse_available
      errors.add(:destination_warehouse_id, "does not exist!") if destination_warehouse_id.present? && Warehouse.not_central.where(id: destination_warehouse_id).select("1 AS one").blank?
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
