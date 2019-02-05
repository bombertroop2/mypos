class Courier < ApplicationRecord
  audited on: [:create, :update]

  has_many :shipments, dependent: :restrict_with_error
  has_many :courier_ways, dependent: :destroy
  has_one :shipment_relation, -> {select("1 AS one")}, class_name: "Shipment"

  accepts_nested_attributes_for :courier_ways, allow_destroy: true

  before_validation :strip_string_values, :upcase_code, :remove_external_courier_additional_fields
  validates :code, :name, :status, presence: true
  validates :terms_of_payment, :value_added_tax_type, presence: true, if: proc{|c| c.status.eql?("External")}
    validates :code, uniqueness: true
    validates :status, uniqueness: true, if: proc{|c| c.status.eql?("Internal")}
      validate :code_not_changed, :status_available, :status_not_changed
      validates :terms_of_payment, numericality: {greater_than_or_equal_to: 1, only_integer: true}, if: proc {|c| c.terms_of_payment.present? && c.status.eql?("External")}
        validate :value_added_tax_type_available, if: proc{|c| c.status.eql?("External")}
        
          before_destroy :delete_tracks
  
          STATUSES = [
            ["Internal", "Internal"],
            ["External", "External"]
          ]
      
          VAT_TYPES = [
            ["Include", "include"],
            ["Exclude", "exclude"],
          ]
     
          def code_and_name
            "#{code} - #{name}"
          end

  
          private
          
          # hapus fields courier external apabila status internal
          def remove_external_courier_additional_fields
            if status.eql?("Internal")
              self.terms_of_payment = 0
              self.value_added_tax_type = ""
            end
          end
          
          def value_added_tax_type_available
            VAT_TYPES.select{ |x| x[1] == value_added_tax_type }.first.first
          rescue
            errors.add(:value_added_tax_type, "does not exist!") if value_added_tax_type.present?
          end
    
          def status_available
            Courier::STATUSES.select{ |x| x[1] == status }.first.first
          rescue
            errors.add(:status, "does not exist!") if status.present?
          end
  
          def delete_tracks
            audits.destroy_all
          end
  
          def code_not_changed
            errors.add(:code, "change is not allowed!") if code_changed? && persisted? && shipment_relation.present?
          end

          def status_not_changed
            errors.add(:status, "change is not allowed!") if status_changed? && persisted?
          end
  
          def strip_string_values
            self.code = code.strip
          end
  
          def upcase_code
            self.code = code.upcase.gsub(" ","").gsub("\t","")
          end
        end
