class Product < ActiveRecord::Base
  belongs_to :brand
  belongs_to :vendor
  belongs_to :model
  belongs_to :goods_type
  
  mount_uploader :image, ImageUploader
  
  has_many :colors, -> {group "common_fields.id"}, through: :product_details
  #  has_many :purchase_order_products
  has_many :product_details, dependent: :destroy
  has_many :product_detail_histories, through: :product_details
  has_many :sizes, -> {group "sizes.id"}, through: :product_details
  #  has_many :purchase_order_details, through: :product_details
  
  
  accepts_nested_attributes_for :product_details,
    reject_if: proc {|attributes| attributes[:cost].blank? and
      attributes[:price].blank? and attributes[:id].blank? }
  
  validates :code, presence: true, uniqueness: true
  validates :effective_date, :brand_id, :sex, :vendor_id, :target, :model_id, :goods_type_id, presence: true
  #  validate :require_at_least_one_detail
  validates :effective_date, date: {after: Proc.new { Date.today }, message: 'must be after today' }, if: :is_validable
  
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
    
    before_validation :upcase_code
  
    private

    def is_validable
      return false unless effective_date.present?
      return true if new_record?
      unless effective_date.eql?(effective_date_was)
        return false if Date.today >= effective_date_was
        return true if Date.today < effective_date_was
      end
      return false
    end
    
    def upcase_code
      self.code = code.upcase
    end
    
    def require_at_least_one_detail
      if product_details.map(&:cost).reject(&:blank?).sum == 0 or product_details.map(&:price).reject(&:blank?).sum == 0
        errors.add(:base, "A product must have at least one detail.")
      end
    end
  end
