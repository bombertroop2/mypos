class PurchaseOrderProduct < ApplicationRecord
  attr_accessor :purchase_order_date, :is_user_adding_new_cost, :po_cost
  
  audited associated_with: :purchase_order, on: [:create, :update]
  has_associated_audits

  belongs_to :purchase_order
  belongs_to :product
  belongs_to :cost_list
  
  has_many :purchase_order_details, dependent: :destroy
  has_many :sizes, -> { group("sizes.id").order(:size) }, through: :purchase_order_details
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :purchase_order_details
  
  
  validate :product_available
  validate :existing_cost, if: proc {|pop| pop.purchase_order_date.present?}

    before_save :set_active_cost, unless: proc {|pop| pop.is_user_adding_new_cost}
      after_update :update_total_unit_cost, if: proc {|pop| pop.cost_list_id_changed?}
        before_destroy :delete_tracks

        accepts_nested_attributes_for :purchase_order_details, allow_destroy: true, reject_if: proc { |attributes| attributes[:quantity].blank? && attributes[:id].blank? }

        def total_quantity
          purchase_order_details.sum :quantity
        end
  
        def total_cost(cost)
          purchase_order_details.sum(:quantity) * cost
        end
  
        private
        
        def delete_tracks
          audits.destroy_all
        end

        def product_available          
          errors.add(:product_id, "does not exist!") if Product.where(id: product_id).select("1 AS one").blank?
        end
    
    
        def update_total_unit_cost
          cost = cost_list.cost
          purchase_order_details.select(:id, :quantity, :total_unit_price).each do |purchase_order_detail|
            purchase_order_detail.is_user_changing_po_date = true
            purchase_order_detail.total_unit_price = cost * purchase_order_detail.quantity
            purchase_order_detail.save
          end
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
