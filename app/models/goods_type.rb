class GoodsType < CommonField
  has_many :products


  before_validation :titleize_name, :upcase_code

  validates :code, uniqueness: true
 

  def titleize_name
    self.name = name.titleize
  end

  def upcase_code
    self.code = code.upcase
  end
end
