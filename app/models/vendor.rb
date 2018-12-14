class Vendor < ApplicationRecord
  audited on: [:create, :update]
  before_validation :strip_string_values

  validates :code, presence: true, uniqueness: true
  validates :name, :address, :terms_of_payment, presence: true
  validates :value_added_tax, presence: true, if: proc {|vendor| vendor.is_taxable_entrepreneur}
    #  validates :email, uniqueness: true, if: proc {|vendor| vendor.email.present?}
    #    validates :pic_email, uniqueness: true, if: proc {|vendor| vendor.pic_email.present?}
    validates :terms_of_payment, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc {|vendor| vendor.terms_of_payment.present?}
      validate :code_not_changed, :vat_available

      
      VAT = [
        ["Include", "include"],
        ["Exclude", "exclude"],
      ]

      has_many :products, dependent: :restrict_with_error
      has_many :purchase_orders, dependent: :restrict_with_error
      has_many :direct_purchases, dependent: :restrict_with_error
      has_many :account_payables, dependent: :restrict_with_error
      has_many :received_purchase_orders, -> { order("received_purchase_orders.id ASC").where("received_purchase_orders.is_using_delivery_order = 'no'") }
      #      has_many :received_direct_purchases, -> { order("received_purchase_orders.id ASC").where("received_purchase_orders.is_using_delivery_order = 'no'") }, class_name: "ReceivedPurchaseOrder"
      has_one :product_relation, -> {select("1 AS one")}, class_name: "Product"
      has_one :purchase_order_relation, -> {select("1 AS one")}, class_name: "PurchaseOrder"
      has_one :account_payable_relation, -> {select("1 AS one")}, class_name: "AccountPayable"
      has_one :direct_purchase_relation, -> {select("1 AS one")}, class_name: "DirectPurchase"
      has_many :po_returns, -> {select(:id, :number, :purchase_order_id, :direct_purchase_id).where(["is_allocated = ?", false])}, through: :purchase_orders, source: :purchase_returns
      has_many :dp_returns, -> {select(:id, :number, :purchase_order_id, :direct_purchase_id).where(["is_allocated = ?", false])}, through: :direct_purchases, source: :purchase_returns


      before_validation :upcase_code
      before_save :remove_vat, if: proc {|vendor| !vendor.value_added_tax_was.eql?("") && vendor.persisted? && !vendor.is_taxable_entrepreneur}
        before_destroy :delete_tracks
        
        def code_and_name
          "#{code} - #{name}"
        end

        private

        def delete_tracks
          audits.destroy_all
        end

        def strip_string_values
          self.code = code.strip
        end
        
        def vat_available
          Vendor::VAT.select{ |x| x[1] == value_added_tax }.first.first
        rescue
          errors.add(:value_added_tax, "does not exist!") if value_added_tax.present?
        end
    
        def remove_vat
          self.value_added_tax = ""
        end
    

        def upcase_code
          self.code = code.upcase.gsub(" ","").gsub("\t","")
        end
    
        def code_not_changed
          errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (product_relation.present? || purchase_order_relation.present? || account_payable_relation.present? || direct_purchase_relation.present?)
        end
      end
