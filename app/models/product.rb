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
  validates :cost, :effective_date, :brand_id, :sex, :vendor_id, :target, :model_id, :goods_type_id, presence: true
  #  validate :require_at_least_one_detail
  validates :effective_date, date: {after_or_equal_to: Proc.new { Date.today }, message: 'must be after or equal to today' }, if: :is_validable
    validates :cost, numericality: true, if: proc { |product| product.cost.present? }
      validates :cost, numericality: {greater_than: 0}, if: proc { |product| product.cost.is_a?(Numeric) }
        validate :require_prices_at_least_one_color_per_price_code

        attr_accessor :size_group
  
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
        
        def require_prices_at_least_one_color_per_price_code          
          if size_group.present?
            sizes_count = SizeGroup.find(size_group).sizes.count rescue 0          
          end
          
          price_code_ids = PriceCode.pluck(:id)
          is_valid = Array.new
          price_code_ids.count.times { is_valid << false }
          
          price_code_ids.each_with_index do |price_code_id, idx|
            Color.pluck(:id).each do |color_id|
              product_details_count = product_details.select {|product_detail| product_detail.color_id == color_id and product_detail.price_code_id == price_code_id}.count
              if sizes_count == product_details_count
                is_valid[idx] = true
                break
              else
                is_valid[idx] = false
              end
            end
          end
          
          errors.add(:base, "A product must have at least one prices detail on one color per price code.") if is_valid.include?(false)
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
    
        def require_at_least_one_detail
          if product_details.map(&:cost).reject(&:blank?).sum == 0 or product_details.map(&:price).reject(&:blank?).sum == 0
            errors.add(:base, "A product must have at least one detail.")
          end
        end
      end
