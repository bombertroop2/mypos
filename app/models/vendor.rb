class Vendor < ApplicationRecord
  audited on: [:create, :update]
  before_validation :strip_string_values, :remove_npwp_attributes, :upcase_code

  validates :code, uniqueness: true
  validates :taxpayer_identification_number, uniqueness: true, if: proc{|v| v.taxpayer_identification_number.strip.present?}
    validates :code, :name, :address, :terms_of_payment, :vendor_type, presence: true
    validates :taxpayer_identification_number, :taxpayer_identification_number_address, presence: true, if: proc{|v| v.vendor_type.eql?("Local") && v.is_taxable_entrepreneur}
      validates :taxpayer_identification_number, presence: true, if: proc{|v| !v.vendor_type.eql?("Local") && v.taxpayer_identification_number_address.present? && v.is_taxable_entrepreneur}
        validates :taxpayer_identification_number_address, presence: true, if: proc{|v| !v.vendor_type.eql?("Local") && v.taxpayer_identification_number.present? && v.is_taxable_entrepreneur}
          validates :value_added_tax, presence: true, if: proc {|vendor| vendor.is_taxable_entrepreneur}
            #  validates :email, uniqueness: true, if: proc {|vendor| vendor.email.present?}
            #    validates :pic_email, uniqueness: true, if: proc {|vendor| vendor.pic_email.present?}
            validates :terms_of_payment, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc {|vendor| vendor.terms_of_payment.present?}
              validate :code_not_changed, :vat_available, :type_available, :value_added_tax_not_changed, :is_taxable_entrepreneur_not_changed

      
              VAT = [
                ["Include", "include"],
                ["Exclude", "exclude"],
              ]

              TYPES = [
                ["Local", "Local"],
                ["Import", "Import"],
                ["Intercompany", "Intercompany"]
              ]

              has_many :products, dependent: :restrict_with_error
              has_many :purchase_orders, dependent: :restrict_with_error
              has_many :direct_purchases, dependent: :restrict_with_error
              has_many :account_payables, dependent: :restrict_with_error
              has_many :account_payable_payments, dependent: :restrict_with_error
              has_many :received_purchase_orders, -> { order("received_purchase_orders.id ASC").where("received_purchase_orders.is_using_delivery_order = 'no'") }
              #      has_many :received_direct_purchases, -> { order("received_purchase_orders.id ASC").where("received_purchase_orders.is_using_delivery_order = 'no'") }, class_name: "ReceivedPurchaseOrder"
              has_one :product_relation, -> {select("1 AS one")}, class_name: "Product"
              has_one :purchase_order_relation, -> {select("1 AS one")}, class_name: "PurchaseOrder"
              has_one :account_payable_relation, -> {select("1 AS one")}, class_name: "AccountPayable"
              has_one :direct_purchase_relation, -> {select("1 AS one")}, class_name: "DirectPurchase"
              has_one :account_payable_payment_relation, -> {select("1 AS one")}, class_name: "AccountPayablePayment"
              has_many :po_returns, -> {select(:id, :number, :purchase_order_id, :direct_purchase_id).where(["is_allocated = ?", false])}, through: :purchase_orders, source: :purchase_returns
              has_many :dp_returns, -> {select(:id, :number, :purchase_order_id, :direct_purchase_id).where(["is_allocated = ?", false])}, through: :direct_purchases, source: :purchase_returns

              before_destroy :delete_tracks
        
              def code_and_name
                "#{code} - #{name}"
              end

              private
              
              def remove_npwp_attributes
                unless is_taxable_entrepreneur
                  self.value_added_tax = ""
                  self.taxpayer_identification_number = ""
                  self.taxpayer_identification_number_address = ""
                end
              end

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
        
              def type_available
                Vendor::TYPES.select{ |x| x[1] == vendor_type }.first.first
              rescue
                errors.add(:vendor_type, "does not exist!") if vendor_type.present?
              end
    
              def upcase_code
                self.code = code.upcase.gsub(" ","").gsub("\t","")
              end
    
              def code_not_changed
                errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (product_relation.present? || purchase_order_relation.present? || account_payable_relation.present? || direct_purchase_relation.present? || account_payable_payment_relation.present?)
              end

              def value_added_tax_not_changed
                errors.add(:value_added_tax, "change is not allowed!") if value_added_tax_changed? && persisted? && purchase_order_relation.present? || account_payable_relation.present? || direct_purchase_relation.present? || account_payable_payment_relation.present?
              end

              def is_taxable_entrepreneur_not_changed
                errors.add(:is_taxable_entrepreneur, "change is not allowed!") if is_taxable_entrepreneur_changed? && persisted? && purchase_order_relation.present? || account_payable_relation.present? || direct_purchase_relation.present? || account_payable_payment_relation.present?
              end
            end
