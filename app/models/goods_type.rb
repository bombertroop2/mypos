class GoodsType < CommonField
  has_many :products, dependent: :restrict_with_error


  before_validation :upcase_code

  validates :code, uniqueness: true
  validate :code_not_changed
 
  private

  def upcase_code
    self.code = code.upcase
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && products.present?
  end
end
