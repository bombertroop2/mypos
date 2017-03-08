class Warehouse < ApplicationRecord
  belongs_to :supervisor
  belongs_to :region
  belongs_to :price_code

  has_many :purchase_orders, dependent: :restrict_with_error
  has_many :sales_promotion_girls, dependent: :restrict_with_error
  has_one :stock, dependent: :restrict_with_error
  has_one :po_relation, -> {select("1 AS one")}, class_name: "PurchaseOrder"
  has_one :spg_relation, -> {select("1 AS one")}, class_name: "SalesPromotionGirl"

  validates :code, :name, :supervisor_id, :region_id, :price_code_id, :address, :warehouse_type, presence: true
  validates :code, length: {minimum: 3, maximum: 4}, if: Proc.new {|warehouse| warehouse.code.present?}
    validate :code_not_changed, :is_area_manager_valid_to_supervise_this_warehouse?
    validates :code, uniqueness: true

    before_validation :upcase_code

    TYPES = [
      ["Central", "central"],
      ["Counter", "counter"],
      ["Showroom", "showroom"]
    ]
    
    def self.has_supervisor?(id)
      SalesPromotionGirl.where(["warehouse_id = ? AND role = 'supervisor'", id]).select("1 AS one").present?
    end
    
    def self.central
      where(warehouse_type: "central")
    end

    private
    
    def is_area_manager_valid_to_supervise_this_warehouse?
      warehouse_types = Warehouse.where(supervisor_id: supervisor_id).pluck(:warehouse_type)
      errors.add(:supervisor_id, "should manage the warehouse with type #{warehouse_types.first}") if !warehouse_types.include?(warehouse_type) && warehouse_types.present?
    end

    def upcase_code
      self.code = code.upcase
    end
    
    def code_not_changed
      errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (spg_relation.present? || po_relation.present? || stock.present?)
    end
  end
