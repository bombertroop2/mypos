class ReceivedPurchaseOrder < ActiveRecord::Base
  belongs_to :purchase_order
  has_many :received_purchase_order_products, dependent: :destroy
  
  
  before_create :create_auto_do_number, if: proc{|rpo| rpo.is_using_delivery_order.eql?("no")}
  
    accepts_nested_attributes_for :received_purchase_order_products, reject_if: :child_blank
  
    validates :delivery_order_number, presence: true, unless: proc{|rpo| rpo.is_using_delivery_order.eql?("no")}, on: :create
      validate :minimum_receiving_item, on: :create
  
  
      private
    
      def create_auto_do_number
        vendor = purchase_order.vendor
        last_received_po = vendor.received_purchase_orders.last
        today = Date.today
        current_month = today.month.to_s.rjust(2, '0')
        current_year = today.strftime("%y").rjust(2, '0')
        if last_received_po
          seq_number = last_received_po.delivery_order_number.split(last_received_po.delivery_order_number.scan(/#{vendor.code}\d.{3}/).first).last.succ
          new_do_number = "#{(vendor.code if vendor)}#{current_month}#{current_year}#{seq_number}"
        else
          new_do_number = "#{(vendor.code if vendor)}#{current_month}#{current_year}001"
        end
        self.delivery_order_number = new_do_number
      end
    
      def minimum_receiving_item
        errors.add(:base, "Please insert at least one item") if received_purchase_order_products.blank?
      end
    
      def child_blank(attributed)
        attributed[:received_purchase_order_items_attributes].each do |key, value| 
          return false if value[:quantity].present?
        end
      
        return true
      end

    end
