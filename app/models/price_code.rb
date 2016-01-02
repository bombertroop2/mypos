class PriceCode < CommonField
  has_many :warehouses, dependent: :restrict_with_error
  has_many :product_details, dependent: :restrict_with_error

  before_validation :titleize_name, :upcase_code

  validates :code, uniqueness: true


  def titleize_name
    self.name = name.titleize
  end

  def upcase_code
    self.code = code.upcase
  end
end
