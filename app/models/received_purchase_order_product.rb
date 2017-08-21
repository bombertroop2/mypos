class ReceivedPurchaseOrderProduct < ApplicationRecord
  attr_accessor :purchase_order_id, :prdct_code, :prdct_name, :prdct_cost
  
  belongs_to :received_purchase_order
  belongs_to :purchase_order_product
  belongs_to :direct_purchase_product
  
  has_many :received_purchase_order_items, dependent: :destroy
  
  accepts_nested_attributes_for :received_purchase_order_items, reject_if: proc { |attributes| attributes[:quantity].blank? }
  
  validates :purchase_order_product_id, presence: true, if: proc{|rpop| rpop.direct_purchase_product_id.blank?}
    validate :purchase_order_product_receivable, if: proc{|rpop| rpop.direct_purchase_product_id.blank?}
    
      private
      
      def purchase_order_product_receivable
        errors.add(:base, "Not able to receive selected products") unless PurchaseOrderProduct.select("1 AS one").joins(:purchase_order).where("(status = 'Open' OR status = 'Partial') AND purchase_orders.id = '#{purchase_order_id}' AND purchase_order_products.id = '#{purchase_order_product_id}'").present?
      end
    end
