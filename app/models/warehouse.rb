class Warehouse < ApplicationRecord
  audited on: [:create, :update]
  belongs_to :supervisor
  belongs_to :region
  belongs_to :price_code

  has_many :listing_stocks, dependent: :restrict_with_error
  has_many :purchase_orders, dependent: :restrict_with_error
  has_many :sales_promotion_girls, dependent: :restrict_with_error
  has_many :origin_warehouse_order_bookings, class_name: "OrderBooking", foreign_key: :origin_warehouse_id, dependent: :restrict_with_error
  has_many :destination_warehouse_order_bookings, class_name: "OrderBooking", foreign_key: :destination_warehouse_id, dependent: :restrict_with_error
  has_many :origin_warehouse_stock_mutations, class_name: "StockMutation", foreign_key: :origin_warehouse_id, dependent: :restrict_with_error
  has_many :destination_warehouse_stock_mutations, class_name: "StockMutation", foreign_key: :destination_warehouse_id, dependent: :restrict_with_error
  has_one :stock, dependent: :restrict_with_error
  has_one :po_relation, -> {select("1 AS one")}, class_name: "PurchaseOrder"
  has_one :spg_relation, -> {select("1 AS one")}, class_name: "SalesPromotionGirl"
  has_one :origin_warehouse_order_booking_relation, -> {select("1 AS one")}, class_name: "OrderBooking", foreign_key: :origin_warehouse_id
  has_one :destination_warehouse_order_booking_relation, -> {select("1 AS one")}, class_name: "OrderBooking", foreign_key: :destination_warehouse_id
  has_one :origin_warehouse_stock_mutation_relation, -> {select("1 AS one")}, class_name: "StockMutation", foreign_key: :origin_warehouse_id
  has_one :destination_warehouse_stock_mutation_relation, -> {select("1 AS one")}, class_name: "StockMutation", foreign_key: :destination_warehouse_id

  validates :code, :name, :supervisor_id, :region_id, :price_code_id, :address, :warehouse_type, presence: true
  validates :code, length: {minimum: 3, maximum: 4}, if: Proc.new {|warehouse| warehouse.code.present?}
    validate :code_not_changed, :is_area_manager_valid_to_supervise_this_warehouse?,
      :area_manager_available, :region_available, :price_code_available, :type_available,
      :warehouse_type_not_changed
    validates :code, uniqueness: true

    before_validation :upcase_code, :strip_string_values
    before_save :empty_messages, unless: proc{|warehouse| warehouse.warehouse_type.eql?("showroom")}
      before_destroy :delete_tracks

      TYPES = [
        ["Central", "central"],
        ["Counter", "counter"],
        ["Showroom", "showroom"]
      ]
    
      def code_and_name
        "#{code} - #{name}"
      end
    
      def self.has_supervisor?(id)
        SalesPromotionGirl.where(["warehouse_id = ? AND role = 'supervisor'", id]).select("1 AS one").present?
      end
    
      def self.central
        where(warehouse_type: "central")
      end
    
      def self.actived
        where(is_active: true)
      end
    
      def self.not_central
        where("warehouse_type <> 'central'")
      end

      private
      
      def empty_messages
        self.first_message = self.second_message = self.third_message = self.fourth_message = self.fifth_message = ""
      end
    
      def delete_tracks
        audits.destroy_all
      end

      def strip_string_values
        self.code = code.strip
      end
    
      def area_manager_available
        errors.add(:supervisor_id, "does not exist!") if supervisor_id.present? && Supervisor.where(id: supervisor_id).select("1 AS one").blank?      
      end

      def region_available
        errors.add(:region_id, "does not exist!") if region_id.present? && Region.where(id: region_id).select("1 AS one").blank?
      end

      def price_code_available
        errors.add(:price_code_id, "does not exist!") if price_code_id.present? && PriceCode.where(id: price_code_id).select("1 AS one").blank?
      end
    
      def type_available
        TYPES.select{ |x| x[1] == warehouse_type }.first.first
      rescue
        errors.add(:warehouse_type, "does not exist!") if warehouse_type.present?
      end

      def is_area_manager_valid_to_supervise_this_warehouse?
        warehouse_types = Warehouse.where(supervisor_id: supervisor_id).pluck(:warehouse_type)
        errors.add(:supervisor_id, "should manage the warehouse with type #{warehouse_types.first}") if !warehouse_types.include?(warehouse_type) && warehouse_types.present?
      end

      def upcase_code
        self.code = code.upcase
      end
    
      def code_not_changed
        errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (spg_relation.present? || po_relation.present? || stock.present? || destination_warehouse_order_booking_relation.present? || origin_warehouse_order_booking_relation.present? || origin_warehouse_stock_mutation_relation.present? || destination_warehouse_stock_mutation_relation.present?)
      end

      def warehouse_type_not_changed
        errors.add(:warehouse_type, "change is not allowed!") if warehouse_type_changed? && persisted? && (destination_warehouse_order_booking_relation.present? || origin_warehouse_order_booking_relation.present? || po_relation.present? || spg_relation.present? || origin_warehouse_stock_mutation_relation.present? || destination_warehouse_stock_mutation_relation.present?)
      end
    end
