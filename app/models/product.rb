class Product < ApplicationRecord
  audited on: [:create, :update]
  has_associated_audits
  #  attr_accessor :effective_date
  
  belongs_to :brand
  belongs_to :vendor
  belongs_to :model
  belongs_to :goods_type
  belongs_to :size_group
  
  mount_uploader :image, ImageUploader
  
  has_many :direct_purchase_products, dependent: :restrict_with_error
  has_many :purchase_order_products, dependent: :restrict_with_error
  has_many :stock_products, dependent: :restrict_with_error
  has_many :order_booking_products, dependent: :restrict_with_error
  has_many :stock_mutation_products, dependent: :restrict_with_error
  has_many :product_details, dependent: :destroy
  has_many :cost_lists, dependent: :destroy
  has_many :product_colors, dependent: :destroy

  has_many :price_codes, -> {group("common_fields.id").order(:code).select(:id, :code)}, through: :product_details
  #  has_many :colors, -> {group("common_fields.id").order(:code)}, through: :product_details
  has_many :sizes, -> {group("sizes.id").order(:size_order).select(:id, :size)}, through: :product_details
  has_many :product_detail_histories, through: :product_details
  has_many :grouped_product_details, -> {joins(:size).group("size_id, barcode, size").select("size_id, barcode, size AS item_size").order(:barcode)}, class_name: "ProductDetail"
  has_many :received_purchase_orders, -> {select("purchase_orders.id").where("purchase_orders.status <> 'Open'")}, through: :purchase_order_products, source: :purchase_order
  has_many :open_purchase_orders, -> {select("purchase_orders.id, purchase_order_date, purchase_orders.order_value").where("purchase_orders.status = 'Open'")}, through: :purchase_order_products, source: :purchase_order
  has_many :color_codes, -> {select(:code)}, through: :product_colors, source: :color
  has_many :colors, -> {select(:id, :code, :name).order(:code)}, through: :product_colors, source: :color
  has_many :prices, -> {select(:price).order(:price)}, through: :product_details, source: :price_lists
  has_one :direct_purchase_product_relation, -> {select("1 AS one")}, class_name: "DirectPurchaseProduct"
  has_one :purchase_order_relation, -> {select("1 AS one").joins(:purchase_order)}, class_name: "PurchaseOrderProduct"
  has_one :stock_product_relation, -> {select("1 AS one")}, class_name: "StockProduct"
  has_one :order_booking_product_relation, -> {select("1 AS one")}, class_name: "OrderBookingProduct"
  has_one :stock_mutation_product_relation, -> {select("1 AS one")}, class_name: "StockMutationProduct"
  
  
  accepts_nested_attributes_for :product_details#, reject_if: :price_blank
  accepts_nested_attributes_for :product_colors, reject_if: proc { |attributes| attributes['selected_color_id'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :cost_lists
  
  before_validation :strip_string_values
  
  validates :code, :size_group_id, :brand_id, :sex, :vendor_id, :target, :model_id, :goods_type_id, presence: true
  validates :code, uniqueness: true
  validate :code_not_changed, :size_group_not_changed, :color_selected
  validate :check_item, on: :create
  validate :brand_available, :sex_available, :vendor_available, :target_available,
    :model_available, :goods_type_available, :size_group_available
  #  validate :check_item, :code_not_changed, :size_group_not_changed, :color_selected
  #        validate :effective_date_not_changed, :cost_not_changed, on: :update
  
  before_validation :upcase_code
  before_update :delete_old_children_if_size_group_changed
  before_destroy :delete_tracks
  #  before_destroy :prevent_delete_if_purchase_order_created

  
  SEX = [
    ["Man", "man"],
    ["Ladies", "ladies"],
    ["Kids", "kids"],
    ["Unisex", "unisex"]
  ]

  TARGETS = [
    ["Normal", "normal"],
    ["Special Price", "special price"],
    ["Sale", "sale"]
  ]
    
  
  def active_cost
    cost_lists = self.cost_lists.select(:id, :cost, :effective_date)
    cost_lists.each do |cost_list|
      if Date.current >= cost_list.effective_date
        return cost_list
      end
    end
    return nil
  end
  
  def active_cost_by_po_date(po_date)
    cost_lists = self.cost_lists.select(:id, :cost, :effective_date)
    cost_lists.each do |cost_list|
      if po_date >= cost_list.effective_date
        return cost_list
      end
    end
  end
  
  def active_effective_date
    cost_lists = self.cost_lists.select(:effective_date)
    cost_lists.each do |cost_list|
      if Time.current.to_date >= cost_list.effective_date
        return cost_list.effective_date
      end
    end
  end
  
  def cost_count
    cost_lists.count(:id)
  end
  
  def product_details_count
    product_details.count(:id)
  end
        
  private
  
  def delete_tracks
    audits.destroy_all
  end

  def strip_string_values
    self.code = code.strip
  end

  
  def brand_available
    errors.add(:brand_id, "does not exist!") if brand_id.present? && Brand.where(id: brand_id).select("1 AS one").blank?
  end

  def vendor_available
    errors.add(:vendor_id, "does not exist!") if vendor_id.present? && Vendor.where(id: vendor_id).select("1 AS one").blank?
  end

  def model_available
    errors.add(:model_id, "does not exist!") if model_id.present? && Model.where(id: model_id).select("1 AS one").blank?
  end

  def goods_type_available
    errors.add(:goods_type_id, "does not exist!") if goods_type_id.present? && GoodsType.where(id: goods_type_id).select("1 AS one").blank?
  end

  def size_group_available
    errors.add(:size_group_id, "does not exist!") if size_group_id.present? && SizeGroup.where(id: size_group_id).select("1 AS one").blank?
  end

  def sex_available
    Product::SEX.select{ |x| x[1] == sex }.first.first
  rescue
    errors.add(:sex, "does not exist!") if sex.present?
  end

  def target_available
    Product::TARGETS.select{ |x| x[1] == target }.first.first
  rescue
    errors.add(:target, "does not exist!") if target.present?
  end
  
  def color_selected
    if new_record?
      valid = if product_colors.present?
        true
      else
        false
      end
    else    
      valid = if product_colors.map(&:_destroy).include?(false)
        true
      else
        false
      end
    end
    errors.add(:base, "Product must have at least one color!") unless valid
  end
  
  
  
  def delete_old_children_if_size_group_changed
    if size_group_id_changed?
      self.product_details.select(:id).each do |product_detail|
        product_detail.destroy unless product_detail.id.nil?
      end
    end
  end
            
  # apabila sudah ada relasi dengan table lain maka tidak dapat ubah code
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (order_booking_product_relation.present? || stock_product_relation.present? || purchase_order_relation.present? || direct_purchase_product_relation.present? || stock_mutation_product_relation.present?)
  end
  
  def size_group_not_changed
    errors.add(:size_group_id, "change is not allowed!") if size_group_id_changed? && persisted? && (order_booking_product_relation.present? || stock_product_relation.present? || purchase_order_relation.present? || direct_purchase_product_relation.present? || cost_lists.select(:id).count > 1 || stock_mutation_product_relation.present?)
  end
        
  def check_item
    valid = if product_details.present?
      true
    else
      false
    end
    errors.add(:base, "Product prices must be filled in!") unless valid
  end
            
  def upcase_code
    self.code = code.upcase
  end
        
end
