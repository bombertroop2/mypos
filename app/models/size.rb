class Size < ApplicationRecord
  belongs_to :size_group
  has_many :product_details, dependent: :restrict_with_error
  has_many :stock_details, dependent: :restrict_with_error
  has_many :order_booking_product_items, dependent: :restrict_with_error
  has_one :product_detail_relation, -> {select("1 AS one")}, class_name: "ProductDetail"
  has_one :stock_detail_relation, -> {select("1 AS one")}, class_name: "StockDetail"
  has_one :order_booking_product_item_relation, -> {select("1 AS one")}, class_name: "OrderBookingProductItem"

  before_validation :strip_string_values
  
  validates :size, presence: true, uniqueness: {scope: :size_group_id}
  validate :size_not_changed
  validate :size_not_added, on: :create
  
  private
  
  def strip_string_values
    self.size = size.strip
  end

  
  # apabila sudah ada relasi dengan table lain maka tidak dapat ubah code
  def size_not_changed
    errors.add(:size, "change is not allowed!") if size_changed? && persisted? && (order_booking_product_item_relation.present? || product_detail_relation.present? || stock_detail_relation.present?)
  end

  # apabila sudah ada relasi dengan table lain maka tidak dapat tambah size
  def size_not_added
    errors.add(:size, "addition is not allowed!") if new_record? && size_group && size_group.product_relation.present?
  end
end
