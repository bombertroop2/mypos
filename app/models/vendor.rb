class Vendor < ApplicationRecord

  validates :code, presence: true, uniqueness: true
  validates :name, :address, :terms_of_payment, presence: true
  validates :value_added_tax, presence: true, if: proc {|vendor| vendor.is_taxable_entrepreneur}
    #  validates :email, uniqueness: true, if: proc {|vendor| vendor.email.present?}
    #    validates :pic_email, uniqueness: true, if: proc {|vendor| vendor.pic_email.present?}
    validates :terms_of_payment, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc {|vendor| vendor.terms_of_payment.present?}
      validate :code_not_changed

      
      VAT = [
        ["Include", "include"],
        ["Exclude", "exclude"],
      ]

      has_many :products, dependent: :restrict_with_error
      has_many :purchase_orders, dependent: :restrict_with_error
      has_many :received_purchase_orders, -> { order("received_purchase_orders.id ASC").where("received_purchase_orders.is_using_delivery_order = 'no'") }, through: :purchase_orders
      has_one :product_relation, -> {select("1 AS one")}, class_name: "Product"
      has_one :purchase_order_relation, -> {select("1 AS one")}, class_name: "PurchaseOrder"


      before_validation :upcase_code
      before_save :remove_vat, if: proc {|vendor| !vendor.value_added_tax_was.eql?("") && vendor.persisted? && !vendor.is_taxable_entrepreneur}
    

        private
    
        def remove_vat
          self.value_added_tax = ""
        end
    

        def upcase_code
          self.code = code.upcase
        end
    
        def code_not_changed
          errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (product_relation.present? || purchase_order_relation.present?)
        end
      end
