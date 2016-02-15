class ReceivedPurchaseOrder < ActiveRecord::Base
  belongs_to :purchase_order_product
  belongs_to :color
  attr_accessor :is_received
  
  after_save :update_receiving_value
  after_destroy :update_receiving_value, :remove_stock
  after_create :create_stock
  
  
  private

  def update_receiving_value
    po = purchase_order_product.purchase_order
    unless self.destroyed?
      po.receiving_value = po.receiving_value.to_f + purchase_order_product.purchase_order_details.select { |pod| pod.color.eql?(color) }.sum(&:total_unit_price)
      po.status = if po.receiving_value != po.order_value
        "Partial"
      else
        "Finish"
      end
      po.save validate: false
    else
      po.receiving_value = po.receiving_value.to_f - purchase_order_product.purchase_order_details.select { |pod| pod.color.eql?(color) }.sum(&:total_unit_price)
      po.status = "Open" if po.receiving_value == 0
      po.save validate: false
    end
  end

  def create_stock    
    po_details = purchase_order_product.purchase_order_details.select { |pod| pod.color.eql?(color) }
    po_details.each do |po_det|
      po_det.build_stock(stock_type: "PO", quantity_on_hand: po_det.quantity)
      po_det.save
    end
  end

  def remove_stock
    po_details = purchase_order_product.purchase_order_details.select { |pod| pod.color.eql?(color) }
    po_details.each do |po_det|
      po_det.stock.destroy if po_det.stock
    end
  end
end
