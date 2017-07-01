class StockMutationProduct < ApplicationRecord
  attr_accessor :origin_warehouse_id
  
  belongs_to :stock_mutation
  belongs_to :product
  has_many :stock_mutation_product_items, dependent: :destroy
  has_many :sizes, -> { group("sizes.id").order(:size) }, through: :stock_mutation_product_items
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :stock_mutation_product_items
  
  accepts_nested_attributes_for :stock_mutation_product_items, reject_if: proc { |attributes| attributes[:quantity].blank? }

  validates :product_id, presence: true
  validate :should_has_details, :product_available

  private
  
  def should_has_details
    errors.add(:base, "Please insert at least one piece per product!") if stock_mutation_product_items.blank?
  end
  
  def product_available
    errors.add(:base, "Some products do not exist!") if StockProduct.joins(:stock).where(product_id: product_id).where(["warehouse_id = ?", origin_warehouse_id]).select("1 AS one").blank?
  end
end