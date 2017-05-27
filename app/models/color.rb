class Color < CommonField
  has_many :purchase_order_details#, dependent: :restrict_with_error
  #  has_many :received_purchase_orders
  has_many :products, -> {group "products.id"}, through: :product_details
  has_many :product_colors, dependent: :restrict_with_error
  has_many :stock_details, dependent: :restrict_with_error
  has_many :order_booking_product_items, dependent: :restrict_with_error
  has_one :product_color_relation, -> {select("1 AS one")}, class_name: "ProductColor"
  has_one :stock_detail_relation, -> {select("1 AS one")}, class_name: "StockDetail"
  has_one :order_booking_product_item_relation, -> {select("1 AS one")}, class_name: "OrderBookingProductItem"

  before_validation :upcase_code

  validates :code, uniqueness: true 
  validate :code_not_changed
  
  private

  def upcase_code
    self.code = code.upcase
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (order_booking_product_item_relation.present? || product_color_relation.present? || stock_detail_relation.present?)
  end
end
