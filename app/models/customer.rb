class Customer < ApplicationRecord
	audited on: [:create, :update]
	before_validation :strip_string_values

	validates :code, presence: true, uniqueness: true
	validates :name, :address, :terms_of_payment, :limit_value, presence: true
	validates :value_added_tax, presence: true, if: proc {|customer| customer.is_taxable_entrepreneur}  
    validates :terms_of_payment, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc {|customer| customer.terms_of_payment.present?}
      validate :vat_available
      validates :limit_value, numericality: {greater_than: 0}, if: proc { |c| c.limit_value.present? && c.limit_value.is_a?(Numeric) }

        VAT = [
          ["Include", "include"],
          ["Exclude", "exclude"],
        ]

        before_validation :upcase_code
        before_save :remove_vat, if: proc {|customer| !customer.value_added_tax_was.eql?("") && customer.persisted? && !customer.is_taxable_entrepreneur}
          before_destroy :delete_tracks

          private

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
