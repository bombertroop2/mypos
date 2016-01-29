class PurchaseOrder < ActiveRecord::Base
  belongs_to :vendor
  belongs_to :warehouse
  
  has_many :purchase_order_products, dependent: :destroy
  has_many :purchase_order_details, through: :purchase_order_products
  has_many :products, -> { group "products.id" }, through: :purchase_order_products
  has_many :received_purchase_orders, through: :purchase_order_products

  attr_accessor :receiving_po
  

  before_validation :generate_number, :set_type, :set_status, on: :create
  
  before_save :calculate_order_value

  before_destroy :prevent_destroy_if_article_received

  validates :number, :vendor_id, :means_of_payment, :request_delivery_date, presence: true, unless: proc { |po| po.receiving_po.eql?("true") }
    validates :number, uniqueness: true, unless: proc { |po| po.receiving_po.eql?("true") }
      validates :means_of_payment, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc { |po| po.means_of_payment.present? && !po.receiving_po.eql?("true") }
        validates :request_delivery_date, date: {after: proc { Date.today }, message: 'must be after today' }, if: :is_validable
#          validate :require_at_least_one_product, unless: proc { |po| po.receiving_po.eql?("true") }
            validate :require_at_least_one_received_color, if: proc { |po| po.receiving_po.eql?("true") }
              validate :prevent_update_if_article_received, on: :update
              validate :disable_receive_po_if_finish, if: proc { |po| po.receiving_po.eql?("true") }

                accepts_nested_attributes_for :purchase_order_products, allow_destroy: true

                private

                def disable_receive_po_if_finish
                  errors.add(:base, "Sorry, this PO's status was finished, you can't edit it anymore") if status_was.eql?("Finish")
                end

                def prevent_destroy_if_article_received
                  if receiving_value.present? && receiving_value > 0
                    errors.add(:base, "Sorry, this PO is not deleteable")
                    return false
                  end
                end

                def prevent_update_if_article_received
                  errors.add(:base, "Sorry, this PO is not updateable") if !receiving_po.eql?("true") && receiving_value.present? && receiving_value > 0
                end

                def require_at_least_one_received_color
                  is_there_color_selected = false
                  purchase_order_products.each do |pop|
                    is_there_color_selected = true unless pop.received_purchase_orders.map(&:is_received).size.eql?(0)
                  end
                  errors.add(:base, "Receiving PO must have at least one product color.") unless is_there_color_selected
                end

                def is_validable
                  return false if receiving_po.eql?("true")
                  return false if request_delivery_date.blank?
                  return true if new_record?
                  unless request_delivery_date.eql?(request_delivery_date_was)
                    return true if request_delivery_date_was.blank?
                    return false if Date.today >= request_delivery_date_was
                    return true if Date.today < request_delivery_date_was
                  end
                  return false
                end

                def calculate_order_value
                  updated_order_value = purchase_order_details.sum(:total_unit_price)
                  unless order_value == updated_order_value
                    self.order_value = updated_order_value
                    save
                  end
                end

                def generate_number
                  last_po = PurchaseOrder.last
                  today = Date.today
                  current_month = today.month.to_s.rjust(2, '0')
                  current_year = today.strftime("%y").rjust(2, '0')
                  if last_po
                    seq_number = last_po.number.split(last_po.number.scan(/PO\d.{3}/).first).last.succ
                    new_po_number = "#{(warehouse.code if warehouse)}PO#{current_month}#{current_year}#{seq_number}"
                  else
                    new_po_number = "#{(warehouse.code if warehouse)}PO#{current_month}#{current_year}0001"
                  end
                  self.number = new_po_number
                end

                def set_type
                  self.po_type = "POC"
                end

                def set_status
                  self.status = "Open"
                end

                def require_at_least_one_product
                  is_there_product_provided = false
                  purchase_order_products.each do |pop|
                    is_there_product_provided = true unless pop.purchase_order_details.map(&:quantity).compact.size.eql?(0)
                  end
                  errors.add(:base, "Purchase order must have at least one product.") unless is_there_product_provided
                end
              end
