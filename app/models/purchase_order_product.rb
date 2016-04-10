class PurchaseOrderProduct < ActiveRecord::Base
  belongs_to :purchase_order
  belongs_to :product
  
  has_many :purchase_order_details, dependent: :destroy
  has_many :sizes, -> { group("sizes.id").order(:size) }, through: :purchase_order_details
  has_many :colors, -> { group("common_fields.id").order(:code) }, through: :purchase_order_details



  accepts_nested_attributes_for :purchase_order_details, allow_destroy: true, reject_if: proc { |attributes| attributes[:quantity].blank? and attributes[:id].blank? }

  def total_quantity
    purchase_order_details.sum :quantity
  end
  
  def total_cost
    purchase_order_details.sum(:quantity) * product.cost
  end
end
