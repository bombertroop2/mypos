class PurchaseOrderProduct < ApplicationRecord
  attr_accessor :purchase_order_date, :is_user_adding_new_cost, :vendor_id
  
  belongs_to :purchase_order
  belongs_to :product
  belongs_to :cost_list
  
  has_many :purchase_order_details, dependent: :destroy
  has_many :sizes, -> { group("sizes.id").order(:size) }, through: :purchase_order_details
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :purchase_order_details
  
  
  validate :existing_cost, if: proc {|pop| pop.purchase_order_date.present?}
    validate :vendor_products, if: proc {|pop| pop.vendor_id.present?}
      validates :vendor_id, presence: true

      before_save :set_active_cost, unless: proc {|pop| pop.is_user_adding_new_cost}
        after_update :update_total_unit_cost, if: proc {|pop| pop.cost_list_id_changed?}

          accepts_nested_attributes_for :purchase_order_details, allow_destroy: true, reject_if: proc { |attributes| attributes[:quantity].blank? and attributes[:id].blank? }

          def total_quantity
            purchase_order_details.sum :quantity
          end
  
          def total_cost
            purchase_order_details.sum(:quantity) * cost_list.cost
          end
  
          private
    
          def vendor_products
            vendor = Vendor.select(:id, :name).where(id: vendor_id).limit(1).first
            is_vendor_having_product = vendor.products.where(id: product_id).select("1 AS one").present?
            errors.add(:base, "This product is not available on #{vendor.name}") unless is_vendor_having_product
          end
    
          def update_total_unit_cost
            cost = cost_list.cost
            purchase_order_details.select(:id, :quantity, :total_unit_price).each do |purchase_order_detail|
              purchase_order_detail.is_user_changing_po_date = true
              purchase_order_detail.total_unit_price = cost * purchase_order_detail.quantity
              purchase_order_detail.save
            end
          end
    
          def set_cost_list_id
            self.cost_list_id = active_cost.id rescue nil
          end
  
          def existing_cost
            errors.add(:base, "Sorry, there is no active cost for product #{product.code} on #{purchase_order_date}") if (@cost = active_cost).blank?
          end
  
          def active_cost
            cost_lists = product.cost_lists.select(:id, :cost, :effective_date).order("effective_date DESC")
            if cost_lists.size == 1
              cost_list = cost_lists.first
              if purchase_order_date.to_date >= cost_list.effective_date
                return cost_list
              end
            else
              cost_lists.each do |cost_list|
                if purchase_order_date.to_date >= cost_list.effective_date
                  return cost_list
                end
              end
            end
          end
  
          def set_active_cost
            self.cost_list_id = @cost.id
          end
        end
