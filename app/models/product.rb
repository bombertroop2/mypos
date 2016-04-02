class Product < ActiveRecord::Base
  belongs_to :brand
  belongs_to :vendor
  belongs_to :model
  belongs_to :goods_type
  belongs_to :size_group
  
  mount_uploader :image, ImageUploader
  
  has_many :price_codes, -> {group("common_fields.id").order(:code)}, through: :product_details
  has_many :product_details, dependent: :destroy
  has_many :colors, -> {group("common_fields.id").order(:code)}, through: :product_details
  has_many :sizes, -> {group("sizes.id").order(:size)}, through: :product_details
  has_many :product_detail_histories, through: :product_details
  has_many :grouped_product_details, -> {group("size_id, barcode").select("size_id, barcode").order(:barcode)}, class_name: "ProductDetail"
  has_many :purchase_order_products, dependent: :restrict_with_error
  #  has_many :purchase_order_details, through: :product_details
  
  accepts_nested_attributes_for :product_details, allow_destroy: true, reject_if: proc {|attributes| attributes[:price].blank? and attributes[:id].blank?}
  
  validates :code, presence: true, uniqueness: true
  validates :size_group_id, :cost, :effective_date, :brand_id, :sex, :vendor_id, :target, :model_id, :goods_type_id, presence: true
  validates :effective_date, date: {after_or_equal_to: Proc.new { Date.today }, message: 'must be after or equal to today' }, if: :is_validable
    validates :cost, numericality: true, if: proc { |product| product.cost.present? }
      validates :cost, numericality: {greater_than: 0}, if: proc { |product| product.cost.is_a?(Numeric) }
        validate :check_item, :code_not_changed
  

  
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
        before_update :is_all_existed_items_deleted?
        
  
        private
        
        # apabila sudah ada relasi dengan table lain maka tidak dapat ubah code
        def code_not_changed
          errors.add(:code, "change is not allowed!") if code_changed? && persisted? && purchase_order_products.present?
        end
        
        def is_all_existed_items_deleted?
          unless product_details.map(&:price).compact.present?
            errors.add(:base, "Product must have at least one item!")
            false
          end
        end
        
        def check_item         
          valid = if product_details.present?
            true
          else
            false
          end
          errors.add(:base, "Product must have at least one item!") unless valid
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
