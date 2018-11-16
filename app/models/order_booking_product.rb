class OrderBookingProduct < ApplicationRecord
  attr_accessor :product_code, :product_name, :attr_destination_warehouse_id
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
    validate :article_sex_not_valid
    
    before_create :calculate_quantity, :update_order_booking_quantity
    before_destroy :delete_tracks
    after_destroy :update_order_booking_quantity
    
    def origin_warehouse_id=(value)
      attribute_will_change!(:origin_warehouse_id)
      @origin_warehouse_id = value
    end
  
    private
    
    def article_sex_not_valid
      if @product.present? && !@product.sex.downcase.eql?("unisex")
        dest_warehouse = Warehouse.select(:code, :counter_type).find(attr_destination_warehouse_id)
        if dest_warehouse.counter_type.blank? || dest_warehouse.counter_type.eql?("Bazar")
        elsif dest_warehouse.counter_type.eql?("Bags")
          if !@product.goods_type_name.strip.downcase.eql?("bag") && !@product.goods_type_name.strip.downcase.eql?("bags")
            errors.add(:base, "Article #{@product.code} is not allowed for warehouse #{dest_warehouse.code}")
          end
        elsif !dest_warehouse.counter_type.downcase.eql?(@product.sex.downcase)
          errors.add(:base, "Article #{@product.code} is not allowed for warehouse #{dest_warehouse.code}")
        end
      end
    end
    
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
        order_booking.with_lock do
          if destroyed?
            order_booking.update_attribute :quantity, last_quantity - quantity
          else
            order_booking.update_attribute :quantity, quantity + last_quantity.to_i
          end
        end
      end
    end
      
    def product_available
      errors.add(:base, "Some products do not exist!") if (@product = Product.joins(:goods_type, stock_products: [stock: :warehouse]).
          where(id: product_id).
          where("stocks.warehouse_id = #{origin_warehouse_id}").
          where(["warehouses.is_active = ?", true]).
          select(:code, :sex, "common_fields.name AS goods_type_name").first).blank?
    end
    
    def calculate_quantity
      quantity = 0
      order_booking_product_items.each do |order_booking_product_item|
        quantity += order_booking_product_item.quantity
      end
      self.quantity = quantity
    end

  end
