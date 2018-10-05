class StockMutationProduct < ApplicationRecord
  attr_accessor :origin_warehouse_id, :product_code, :product_name, :attr_destination_warehouse_id
  
  audited associated_with: :stock_mutation, on: [:create, :update]
  has_associated_audits

  belongs_to :stock_mutation
  belongs_to :product
  has_many :stock_mutation_product_items, dependent: :destroy
  has_many :sizes, -> { group("sizes.id").order(:size_order) }, through: :stock_mutation_product_items
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :stock_mutation_product_items
  
  accepts_nested_attributes_for :stock_mutation_product_items, allow_destroy: true

  validates :product_id, presence: true
  #  validate :should_has_details
  validate :product_available
  validate :article_sex_not_valid

  before_destroy :delete_tracks

  private
  
  def article_sex_not_valid
    if @sp.present? && !@sp.product_sex.downcase.eql?("unisex") && attr_destination_warehouse_id.present?
      dest_warehouse = Warehouse.select(:code, :counter_type).find(attr_destination_warehouse_id)
      if dest_warehouse.counter_type.blank? || dest_warehouse.counter_type.eql?("Bazar")
      elsif dest_warehouse.counter_type.eql?("Bags")
        if !@sp.goods_type_name.strip.downcase.eql?("bag") && !@sp.goods_type_name.strip.downcase.eql?("bags")
          errors.add(:base, "Article #{@sp.product_code} is not allowed for warehouse #{dest_warehouse.code}")
        end
      elsif !dest_warehouse.counter_type.downcase.eql?(@sp.product_sex.downcase)
        errors.add(:base, "Article #{@sp.product_code} is not allowed for warehouse #{dest_warehouse.code}")
      end
    end
  end
  
  def delete_tracks
    audits.destroy_all
  end
  
  #  def should_has_details
  #    errors.add(:base, "Please insert at least one piece per product!") if stock_mutation_product_items.blank?
  #  end
  
  def product_available
    errors.add(:base, "Some products do not exist!") if (@sp = StockProduct.joins(:stock, product: :goods_type).where(product_id: product_id).where(["warehouse_id = ?", origin_warehouse_id]).select("products.code AS product_code", "products.sex AS product_sex", "common_fields.name AS goods_type_name").first).blank?
  end
end
