class PriceCode < CommonField
  has_many :warehouses, dependent: :restrict_with_error
  has_many :product_details, dependent: :restrict_with_error
  has_one :warehouse_relation, -> {select("1 AS one")}, class_name: "Warehouse"
  has_one :product_detail_relation, -> {select("1 AS one")}, class_name: "ProductDetail"

  before_validation :upcase_code

  #  validates :code, uniqueness: true # tidak menggunakan ini untuk mempercepat proses
  validate :code_not_changed

  private

  def upcase_code
    self.code = code.upcase
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (warehouse_relation.present? || product_detail_relation.present?)
  end
end
