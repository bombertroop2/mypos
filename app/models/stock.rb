class Stock < ActiveRecord::Base
  belongs_to :warehouse
  
  has_many :stock_products
  has_many :stock_details, through: :stock_products
  
  def product_cost
    purchase_order_detail.purchase_order_product.product.cost
  end
  
  def po_number
    purchase_order_detail.purchase_order_product.purchase_order.number
  end
  
  def warehouse_code
    purchase_order_detail.purchase_order_product.purchase_order.warehouse.code
  end
  
  def product_code
    purchase_order_detail.purchase_order_product.product.code
  end
  
  def product_color
    purchase_order_detail.color.code
  end
  
  def product_size
    purchase_order_detail.size.size
  end
end
