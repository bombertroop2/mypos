class Color < CommonField
  has_many :purchase_order_details#, dependent: :restrict_with_error
  #  has_many :received_purchase_orders
  has_many :products, -> {group "products.id"}, through: :product_details
  has_many :product_colors, dependent: :restrict_with_error
  has_many :stock_details, dependent: :restrict_with_error
  has_one :product_color_relation, -> {select("1 AS one")}, class_name: "ProductColor"
  has_one :stock_detail_relation, -> {select("1 AS one")}, class_name: "StockDetail"

  before_validation :upcase_code

  validates :code, uniqueness: true 
  validate :code_not_changed
  
  private

  def upcase_code
    self.code = code.upcase
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (product_color_relation.present? || stock_detail_relation.present?)
  end
end
