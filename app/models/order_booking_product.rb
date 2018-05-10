class OrderBookingProduct < ApplicationRecord
  attr_accessor :product_code, :product_name
  attr_reader :origin_warehouse_id
  
  audited associated_with: :order_booking, on: :create
  has_associated_audits

  belongs_to :order_booking
  belongs_to :product
  
  has_many :order_booking_product_items, dependent: :destroy
  has_many :sizes, -> {group(:id).select(:id, :size)}, through: :order_booking_product_items
  has_many :colors, -> {group(:id).select(:id, :code, :name)}, through: :order_booking_product_items
  
  accepts_nested_attributes_for :order_booking_product_items, reject_if: proc {|attributes| attributes[:quantity].blank? && attributes[:id].blank?}
  
  validates :product_id, presence: true
  validate :product_available, if: proc{|obp| obp.product_id.present? && (obp.new_record? || (obp.product_id_changed? && obp.persisted?))}
    validate :check_min_product_quantity
    
    before_create :calculate_quantity, :update_order_booking_quantity
    before_destroy :delete_tracks
    after_destroy :update_order_booking_quantity
    
    def origin_warehouse_id=(value)
      attribute_will_change!(:origin_warehouse_id)
      @origin_warehouse_id = value
    end
  
    private
    
    def delete_tracks
      audits.destroy_all
    end
    
    def check_min_product_quantity
      if new_record?
        errors.add(:base, "Order booking must have at least one quantity per product") if order_booking_product_items.blank?
      end
    end
    
    def update_order_booking_quantity
      last_quantity = order_booking.quantity
      order_booking.without_auditing do
        if destroyed?
          order_booking.update_attribute :quantity, last_quantity - quantity
        else
          order_booking.update_attribute :quantity, quantity + last_quantity.to_i
        end
      end
    end
      
    def product_available
      errors.add(:base, "Some products do not exist!") if Product.joins(stock_products: [stock: :warehouse]).
        where(id: product_id).
        where("stocks.warehouse_id = #{origin_warehouse_id}").
        where(["warehouses.is_active = ?", true]).
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
