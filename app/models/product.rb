class Product < ActiveRecord::Base
  attr_accessor :effective_date
  
  belongs_to :brand
  belongs_to :vendor
  belongs_to :model
  belongs_to :goods_type
  belongs_to :size_group
  
  mount_uploader :image, ImageUploader
  
  has_many :price_codes, -> {group("common_fields.id").order(:code)}, through: :product_details
  has_many :product_details, dependent: :destroy
  has_many :colors, -> {group("common_fields.id").order(:code)}, through: :product_details
  has_many :sizes, -> {group("sizes.id").order(:size).select(:id, :size)}, through: :product_details
  has_many :product_detail_histories, through: :product_details
  has_many :grouped_product_details, -> {group("size_id, barcode").select("size_id, barcode").order(:barcode)}, class_name: "ProductDetail"
  has_many :purchase_order_products
  has_many :cost_lists, dependent: :destroy
  has_many :received_purchase_orders, -> {select("purchase_orders.id").where("purchase_orders.status <> 'Open' AND purchase_orders.status <> 'Deleted'")}, through: :purchase_order_products, source: :purchase_order
  has_many :open_purchase_orders, -> {select("purchase_orders.id, purchase_order_date, purchase_orders.order_value, purchase_orders.price_discount").where("purchase_orders.status = 'Open'")}, through: :purchase_order_products, source: :purchase_order
  has_many :direct_purchase_products, dependent: :restrict_with_error
  has_one :direct_purchase_product_relation, -> {select("1 AS one")}, class_name: "DirectPurchaseProduct"
  has_one :purchase_order_relation, -> {select("1 AS one").joins(:purchase_order).where("purchase_orders.status <> 'Deleted'")}, class_name: "PurchaseOrderProduct"
  
  
  accepts_nested_attributes_for :product_details, reject_if: :price_blank
  accepts_nested_attributes_for :cost_lists
  
  validates :code, :size_group_id, :brand_id, :sex, :vendor_id, :target, :model_id, :goods_type_id, presence: true
  validate :check_item, :code_not_changed, :size_group_not_changed
  #        validate :effective_date_not_changed, :cost_not_changed, on: :update
  
  before_validation :upcase_code
  before_update :delete_old_children_if_size_group_changed
  before_destroy :prevent_delete_if_purchase_order_created

  
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
    cost_lists = self.cost_lists.select(:id, :cost, :effective_date).order("effective_date DESC")
    if cost_lists.size == 1
      cost_list = cost_lists.first
      if Date.today >= cost_list.effective_date
        return cost_list
      end
    else
      cost_lists.each do |cost_list|
        if Date.today >= cost_list.effective_date
          return cost_list
        end
      end
    end
  end
  
  def active_cost_by_po_date(po_date)
    cost_lists = self.cost_lists.select(:id, :cost, :effective_date).order("effective_date DESC")
    if cost_lists.size == 1
      cost_list = cost_lists.first
      if po_date >= cost_list.effective_date
        return cost_list
      end
    else
      cost_lists.each do |cost_list|
        if po_date >= cost_list.effective_date
          return cost_list
        end
      end
    end
  end
  
  def active_effective_date
    cost_lists = self.cost_lists.select(:effective_date).order("effective_date DESC")
    if cost_lists.size == 1
      return cost_lists.first.effective_date
    else
      cost_lists.each do |cost_list|
        if Date.today >= cost_list.effective_date
          return cost_list
        end
      end
      cost_lists.last.effective_date
    end
  end
  
  def cost_count
    cost_lists.count(:id)
  end
  
  def product_details_count
    product_details.count(:id)
  end
        
  private
  
  def prevent_delete_if_purchase_order_created   
    if purchase_order_relation
      errors.add(:base, "Cannot delete record with purchase order")
      return false
    end
  end
  
  
  def delete_old_children_if_size_group_changed
    if size_group_id_changed?
      self.product_details.each do |product_detail|
        product_detail.destroy unless product_detail.id.nil?
      end
    end
  end
    
  def price_blank(attributed)
    attributed[:price_lists_attributes].each do |key, value|
      return false if attributed[:price_lists_attributes][key][:price].present?
    end
      
    return true
  end
        
  #        def update_po_active_cost(purchase_order_date)
  #          cost_lists = self.cost_lists.select(:id, :cost, :effective_date).order("id DESC")
  #          if cost_lists.size == 1
  #            return cost_lists.first
  #          else
  #            cost_lists.each do |cost_list|
  #              if purchase_order_date >= cost_list.effective_date
  #                return cost_list
  #              end
  #            end
  #          end
  #        end
        
  #        def update_purchase_order_cost
  #          if !effective_date_was.eql?(effective_date) || !cost_was.eql?(cost)
  #            total_product_value = 0
  #            open_purchase_orders.each do |open_purchase_order|
  #              new_po_cost = []
  #              purchase_order_products = PurchaseOrderProduct.joins(:purchase_order).where("purchase_orders.id = #{open_purchase_order.id}").select("cost_list_id, purchase_order_products.id, product_id")
  #              purchase_order_products.each_with_index do |purchase_order_product, index|
  #                if purchase_order_product.product_id.eql?(id)
  #                  new_po_cost << update_po_active_cost(open_purchase_order.purchase_order_date)
  #                end
  #                total_quantity = purchase_order_product.purchase_order_details.sum :quantity
  #                if purchase_order_product.product_id.eql?(id)
  #                  total_product_value += new_po_cost[index].cost * total_quantity
  #                else
  #                  total_product_value += purchase_order_product.cost_list.cost * total_quantity
  #                end
  #              end
  #              
  #              unless open_purchase_order.order_value == total_product_value
  #                if (open_purchase_order.price_discount.present? && open_purchase_order.price_discount <= total_product_value) || open_purchase_order.price_discount.blank?
  #                  open_purchase_order.changing_po_cost = true
  #                  open_purchase_order.order_value = total_product_value
  #                  open_purchase_order.save validate: false
  #                  purchase_order_products.each_with_index do |purchase_order_product, index|
  #                    if purchase_order_product.product_id.eql?(id)
  #                      purchase_order_product.cost_list_id = new_po_cost[index].id
  #                      if purchase_order_product.save
  #                        purchase_order_product.purchase_order_details.each do |purchase_order_detail|
  #                          purchase_order_detail.changing_po_cost = true
  #                          purchase_order_detail.total_unit_price = purchase_order_detail.quantity * new_po_cost[index].cost
  #                          purchase_order_detail.save validate: false
  #                        end
  #                      end
  #                    end
  #                  end
  #                else
  #                  errors.add(:effective_date, "change is not allowed! Please decrease the price discount")
  #                  return false
  #                end
  #              end              
  #            end
  #          elsif cost_changed?
  #          end
  #        end
                
        
  #        def update_cost_list
  #          if (effective_date_changed? || cost_changed?) && persisted? && !is_user_adding_new_cost
  #            # ambil cost terakhir dari list
  #            last_cost = cost_lists.last
  #            last_cost.effective_date = effective_date
  #            last_cost.cost = cost
  #            last_cost.save
  #          elsif is_user_adding_new_cost
  #            create_cost_list
  #          end
  #        end
        
        
  #        def cost_not_changed
  #          errors.add(:cost, "change is not allowed!") if cost_changed? && persisted? && (Date.today >= effective_date_was || received_purchase_orders.present? || direct_purchase_product_relation.present?) && !is_user_adding_new_cost
  #        end
  #        
  #        # cegah user mengubah effective date apabila hari ini sama dengan atau lebih besar dari effective date yang lalu
  #        def effective_date_not_changed          
  #          errors.add(:effective_date, "change is not allowed!") if effective_date_changed? && persisted? && (Date.today >= effective_date_was || received_purchase_orders.present? || direct_purchase_product_relation.present?) && !is_user_adding_new_cost
  #        end
        
  # apabila sudah ada relasi dengan table lain maka tidak dapat ubah code
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (purchase_order_relation.present? || direct_purchase_product_relation.present?)
  end
  
  def size_group_not_changed
    errors.add(:size_group_id, "change is not allowed!") if size_group_id_changed? && persisted? && (purchase_order_relation.present? || direct_purchase_product_relation.present?)
  end
        
  #        def is_all_existed_items_deleted?
  #          unless product_details.map(&:price).compact.present?
  #            errors.add(:base, "Product must have at least one item!")
  #            false
  #          end
  #        end
        
  def check_item
    if new_record?
      valid = if product_details.present?
        true
      else
        false
      end
    else    
      valid = if !size_group_id_changed? || (size_group_id_changed? && product_details.select{|product_detail| product_detail.id.nil?}.present?)
        true
      else
        false
      end
    end
    errors.add(:base, "Product must have at least one item!") unless valid
  end
            
  def upcase_code
    self.code = code.upcase
  end
        
  #        protected
  #        
  #        def is_user_adding_new_cost          
  #          last_cost = cost_lists.last
  #          if effective_date > last_cost.effective_date && Date.today >= last_cost.effective_date && cost_changed? && persisted?
  #            return true
  #          else
  #            return false
  #          end
  #        end
    
end
