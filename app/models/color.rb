class Color < CommonField
  attr_accessor :attr_importing_data

  audited on: [:create, :update]
  has_many :purchase_order_details#, dependent: :restrict_with_error
  #  has_many :received_purchase_orders
  has_many :products, -> {group "products.id"}, through: :product_details
  has_many :listing_stock_product_details, dependent: :restrict_with_error
  has_many :product_colors, dependent: :restrict_with_error
  has_many :stock_details, dependent: :restrict_with_error
  has_many :order_booking_product_items, dependent: :restrict_with_error
  has_many :stock_mutation_product_items, dependent: :restrict_with_error
  has_many :adjustment_product_details, dependent: :restrict_with_error
  has_one :product_color_relation, -> {select("1 AS one")}, class_name: "ProductColor"
  has_one :stock_detail_relation, -> {select("1 AS one")}, class_name: "StockDetail"
  has_one :order_booking_product_item_relation, -> {select("1 AS one")}, class_name: "OrderBookingProductItem"
  has_one :stock_mutation_product_item_relation, -> {select("1 AS one")}, class_name: "StockMutationProductItem"
  has_one :adjustment_product_detail_relation, -> {select("1 AS one")}, class_name: "AdjustmentProductDetail"

  before_validation :upcase_code, unless: proc{|c| c.attr_importing_data}

  validates :code, uniqueness: true 
  validate :code_not_changed
  
  before_destroy :delete_tracks

  private

  def delete_tracks
    audits.destroy_all
  end

  def upcase_code
    self.code = code.upcase.gsub(" ","").gsub("\t","")
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (order_booking_product_item_relation.present? || product_color_relation.present? || stock_detail_relation.present? || stock_mutation_product_item_relation.present? || adjustment_product_detail_relation.present?)
  end
end
