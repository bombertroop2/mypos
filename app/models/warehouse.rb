class Warehouse < ActiveRecord::Base
  belongs_to :supervisor
  belongs_to :region
  belongs_to :price_code

  has_many :purchase_orders, dependent: :restrict_with_error
  has_many :sales_promotion_girls, dependent: :restrict_with_error
  #  has_many :purchase_order_products

  validates :code, :name, :supervisor_id, :region_id, :price_code_id, :address, :warehouse_type, presence: true
  validates :code, uniqueness: true, length: {minimum: 3, maximum: 4}, if: Proc.new {|warehouse| warehouse.code.present?}
    validate :code_not_changed

    before_validation :upcase_code

    TYPES = [
      ["Central", "central"],
      ["Counter", "counter"],
      ["Showroom", "showroom"]
    ]

    private

    def upcase_code
      self.code = code.upcase
    end
    
    def code_not_changed
      errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (sales_promotion_girls.present? || purchase_orders.present?)
    end
  end
