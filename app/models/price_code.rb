class PriceCode < CommonField
  has_many :warehouses, dependent: :restrict_with_error
  has_many :product_details, dependent: :restrict_with_error

  before_validation :upcase_code

  validates :code, uniqueness: true
  validate :code_not_changed

  private

  def upcase_code
    self.code = code.upcase
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (warehouses.present? || product_details.present?)
  end
end
