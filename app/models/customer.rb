class Customer < ApplicationRecord
	audited on: [:create, :update]
  
  belongs_to :province
  belongs_to :city
  has_one :order_booking_relation, -> {select("1 AS one")}, class_name: "OrderBooking"
  has_many :order_bookings, dependent: :restrict_with_error
  has_many :accounts_receivable_payments, dependent: :restrict_with_error

	before_validation :strip_string_values, :set_limit_value_to_zero

	validates :code, presence: true, uniqueness: true
	validates :name, :address, :terms_of_payment, :deliver_to, :province_id, :city_id, :discount, presence: true
  validates :discount, numericality: {greater_than_or_equal_to: 0, less_than: 100}, if: proc {|c| c.discount.present?}
    validates :limit_value, presence: true, unless: proc{|c| c.unlimited} 
      validates :value_added_tax, presence: true, if: proc {|customer| customer.is_taxable_entrepreneur}  
        validates :terms_of_payment, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc {|customer| customer.terms_of_payment.present?}
          validate :vat_available
          validates :limit_value, numericality: {greater_than: 0}, if: proc { |c| c.limit_value.present? && c.limit_value.is_a?(Numeric) && !c.unlimited}
            validate :code_not_changed, :city_available, :city_id_not_changed, :is_taxable_entrepreneur_not_changed, :value_added_tax_not_changed

            VAT = [
              ["Include", "include"],
              ["Exclude", "exclude"],
            ]

            before_validation :upcase_code
            before_save :remove_vat, if: proc {|customer| !customer.value_added_tax_was.eql?("") && customer.persisted? && !customer.is_taxable_entrepreneur}
              before_destroy :delete_tracks
          
              def code_and_name
                "#{code} - #{name}"
              end

              private
          
              def set_limit_value_to_zero
                self.limit_value = 0 if unlimited
              end
          
              def city_available
                errors.add(:city_id, "does not exist!") if province_id.present? && city_id.present? && (province_id_changed? || city_id_changed?) && City.select("1 AS one").where(id: city_id, province_id: province_id).blank?
              end

              def code_not_changed
                errors.add(:code, "change is not allowed!") if code_changed? && persisted? && (order_booking_relation.present? || accounts_receivable_payments.select("1 AS one").present?)
              end

              def is_taxable_entrepreneur_not_changed
                errors.add(:is_taxable_entrepreneur, "change is not allowed!") if is_taxable_entrepreneur_changed? && persisted? && accounts_receivable_payments.select("1 AS one").present?
              end

              def value_added_tax_not_changed
                errors.add(:value_added_tax, "change is not allowed!") if value_added_tax_changed? && persisted? && accounts_receivable_payments.select("1 AS one").present?
              end

              def city_id_not_changed
                errors.add(:city_id, "change is not allowed!") if province_id.present? && city_id.present? && (province_id_changed? || city_id_changed?) && (province_id_was.present? || city_id_was.present?) && persisted? && order_booking_relation.present?
              end

              def delete_tracks
                audits.destroy_all
              end

              def strip_string_values
                self.code = code.strip
              end

              def vat_available
                Customer::VAT.select{ |x| x[1] == value_added_tax }.first.first
              rescue
                errors.add(:value_added_tax, "does not exist!") if value_added_tax.present?
              end

              def remove_vat
                self.value_added_tax = ""
              end


              def upcase_code
                self.code = code.upcase.gsub(" ","").gsub("\t","")
              end
            end
