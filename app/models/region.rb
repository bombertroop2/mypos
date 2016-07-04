class Region < CommonField
  has_many :warehouses, dependent: :restrict_with_error
  has_many :sales_promotion_girls, through: :warehouses
  has_many :supervisors, through: :warehouses
  has_one :warehouse_relation, -> {select("1 AS one")}, class_name: "Warehouse"

  before_validation :upcase_code

  #  validates :code, uniqueness: true # tidak menggunakan ini untuk mempercepat proses
  validate :code_not_changed

  private

  def upcase_code
    self.code = code.upcase
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && warehouse_relation.present?
  end
end
