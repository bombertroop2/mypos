class Product < ActiveRecord::Base
  belongs_to :brand
  belongs_to :vendor
  belongs_to :model
  belongs_to :goods_type
  belongs_to :size_group
  
  mount_uploader :image, ImageUploader
  
  has_many :product_price_codes, dependent: :destroy
  has_many :price_codes, through: :product_price_codes  
  has_many :product_details, through: :product_price_codes  
  has_many :colors, -> {group("common_fields.id").order(:code)}, through: :product_details
  has_many :sizes, -> {group("sizes.id").order(:size)}, through: :product_details
  has_many :product_detail_histories, through: :product_details
  has_many :grouped_product_details, -> {group("size_id, color_id")}, through: :product_price_codes,  source: :product_details
  #  has_many :purchase_order_details, through: :product_details
  #  has_many :purchase_order_products  
  
  accepts_nested_attributes_for :product_price_codes, allow_destroy: true
  
  validates :code, presence: true, uniqueness: true
  validates :size_group_id, :cost, :effective_date, :brand_id, :sex, :vendor_id, :target, :model_id, :goods_type_id, presence: true
  validates :effective_date, date: {after_or_equal_to: Proc.new { Date.today }, message: 'must be after or equal to today' }, if: :is_validable
    validates :cost, numericality: true, if: proc { |product| product.cost.present? }
      validates :cost, numericality: {greater_than: 0}, if: proc { |product| product.cost.is_a?(Numeric) }
        validate :validate_product_price_codes
  

  
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
    
        before_validation :upcase_code, :remove_old_product_details
        
  
        private
        
        #        def get_newest_product_detail_ids
        #          @newest_product_detail_ids = product_details.pluck(:id) unless size_group_id_was.eql?(size_group_id)
        #        end
        
        def remove_old_product_details
          product_price_codes.each do |ppc|
            oldest_product_detail_ids = ppc.product_details.pluck(:id)
            ProductDetail.destroy_all(['id IN (?)', oldest_product_detail_ids]) if oldest_product_detail_ids.present?
          end unless size_group_id_was.eql?(size_group_id)
        end
        
        def validate_product_price_codes
          errors.add(:base, "You should add at least one price code per product") if product_price_codes.size < 1
        end

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
    
      end
