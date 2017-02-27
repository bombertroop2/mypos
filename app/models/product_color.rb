class ProductColor < ApplicationRecord
  belongs_to :product
  belongs_to :color
  
  attr_accessor :code, :name, :selected_color_id
  
  before_destroy :prevent_deleting_if_po_is_created
  
  private
  
  def prevent_deleting_if_po_is_created
    throw :abort if Product.select(:id).where(id: product_id).first.purchase_order_relation.present?
  end
end
