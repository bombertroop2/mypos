class Color < CommonField
  has_many :purchase_order_details, dependent: :restrict_with_error
  #  has_many :received_purchase_orders
  has_many :products, -> {group "products.id"}, through: :product_details

  before_validation :upcase_code

  validates :code, uniqueness: true
  validate :code_not_changed
  
  private

  def upcase_code
    self.code = code.upcase
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && purchase_order_details.present?
  end
end
