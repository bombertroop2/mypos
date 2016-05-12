class DirectPurchaseProduct < ActiveRecord::Base
  belongs_to :direct_purchase
  belongs_to :product
  belongs_to :cost_list
  
  has_one :received_purchase_order_product, dependent: :destroy
  has_many :direct_purchase_details, dependent: :destroy
  
  validate :should_has_details, on: :create
  
  accepts_nested_attributes_for :received_purchase_order_product
  accepts_nested_attributes_for :direct_purchase_details, reject_if: proc { |attributes| attributes[:quantity].blank? }

  before_create :create_received_purchase_order_product, :set_active_cost

  
  def active_cost(receiving_date)
    cost_lists = product.cost_lists.select(:id, :cost, :effective_date).order("effective_date DESC")
    if cost_lists.size == 1
      cost_list = cost_lists.first
      if receiving_date >= cost_list.effective_date
        return cost_list
      end
    else
      cost_lists.each_with_index do |cost_list, index|
        if receiving_date >= cost_list.effective_date
          return cost_list
        end
      end
    end
  end
  
  private
  
  def should_has_details    
    errors.add(:base, "Please insert at least one piece per product!") if direct_purchase_details.blank?
  end
  
  def create_received_purchase_order_product
    self.attributes = self.attributes.merge(received_purchase_order_product_attributes: {
        received_purchase_order_id: direct_purchase.received_purchase_order.id,
        direct_purchase_product_id: id
      })
  end
  
  def set_active_cost
    self.cost_list_id = active_cost(direct_purchase.receiving_date).id
  end
end
