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
  has_many :cost_lists, dependent: :destroy
  has_many :not_open_purchase_orders, -> {select("purchase_orders.id").where("purchase_orders.status <> 'Open'")}, through: :purchase_order_products, source: :purchase_order
  
  accepts_nested_attributes_for :product_details, allow_destroy: true, reject_if: proc {|attributes| attributes[:price].blank? and attributes[:id].blank?}
  accepts_nested_attributes_for :cost_lists
  
  validates :code, presence: true, uniqueness: true
  validates :size_group_id, :cost, :effective_date, :brand_id, :sex, :vendor_id, :target, :model_id, :goods_type_id, presence: true
  validates :effective_date, date: {after_or_equal_to: Proc.new { Date.today }, message: 'must be after or equal to today' }, if: proc {|product| product.effective_date.present? && (product.new_record? || Date.today < product.effective_date_was)}
    validates :cost, numericality: true, if: proc { |product| product.cost.present? }
      validates :cost, numericality: {greater_than: 0}, if: proc { |product| product.cost.is_a?(Numeric) }
        validate :check_item, :code_not_changed
        validate :effective_date_not_changed, :cost_not_changed, on: :update
  

  
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
        before_update :is_all_existed_items_deleted?, :update_cost_list
        before_create :create_cost_list
        
  
        private
        
        def is_user_adding_new_cost          
          last_cost = cost_lists.last
          if effective_date > last_cost.effective_date && Date.today >= last_cost.effective_date && cost_changed? && persisted?
            return true
          else
            return false
          end
        end
        
        def update_cost_list
          if (effective_date_changed? || cost_changed?) && persisted? && !is_user_adding_new_cost
            # ambil cost terakhir dari list
            last_cost = cost_lists.last
            last_cost.effective_date = effective_date
            last_cost.cost = cost
            last_cost.save
          elsif is_user_adding_new_cost
            create_cost_list
          end
        end
        
        def create_cost_list
          self.attributes = self.attributes.merge(cost_lists_attributes: {"0" => {
                effective_date: self.effective_date,
                cost: self.cost,
                product_id: self.id
              }})
        end
        
        def cost_not_changed
          errors.add(:cost, "change is not allowed!") if cost_changed? && persisted? && (Date.today >= effective_date_was || not_open_purchase_orders.present?) && !is_user_adding_new_cost
        end
        
        # cegah user mengubah effective date apabila hari ini sama dengan atau lebih besar dari effective date yang lalu
        def effective_date_not_changed
          errors.add(:effective_date, "change is not allowed!") if effective_date_changed? && persisted? && (Date.today >= effective_date_was || not_open_purchase_orders.present?) && !is_user_adding_new_cost
        end
        
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
            
        def upcase_code
          self.code = code.upcase
        end
    
      end
