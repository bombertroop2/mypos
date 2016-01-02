class Region < CommonField
  has_many :warehouses, dependent: :restrict_with_error
  has_many :sales_promotion_girls, through: :warehouses
  has_many :supervisors, through: :warehouses

  before_validation :titleize_name, :upcase_code

  validates :code, uniqueness: true


  def titleize_name
    self.name = name.titleize
  end

  def upcase_code
    self.code = code.upcase
  end
end
