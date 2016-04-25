class GoodsType < CommonField
  has_many :products, dependent: :restrict_with_error
  has_one :product_relation, -> {select("id")}, class_name: "Product"

  before_validation :upcase_code

  #  validates :code, uniqueness: true # tidak menggunakan ini untuk mempercepat proses
  validate :code_not_changed
 
  private

  def upcase_code
    self.code = code.upcase
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && product_relation.present?
  end
end
