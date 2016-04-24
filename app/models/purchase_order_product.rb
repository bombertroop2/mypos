class PurchaseOrderProduct < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :product
  belongs_to :cost_list
  
  has_many :purchase_order_details, dependent: :destroy
  has_many :sizes, -> { group("sizes.id").order(:size) }, through: :purchase_order_details
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :purchase_order_details

  before_create :set_active_cost

  accepts_nested_attributes_for :purchase_order_details, allow_destroy: true, reject_if: proc { |attributes| attributes[:quantity].blank? and attributes[:id].blank? }

  def total_quantity
    purchase_order_details.sum :quantity
  end
  
  def total_cost
    purchase_order_details.sum(:quantity) * cost_list.cost
  end
  
  private
  
  def set_active_cost
    self.cost_list_id = product.active_cost.id
  end
end
