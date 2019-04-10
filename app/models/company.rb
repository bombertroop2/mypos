class Company < ApplicationRecord
  has_many :company_banks, dependent: :destroy

  accepts_nested_attributes_for :company_banks, allow_destroy: true

  before_validation :strip_field_values

  validates :code, :name, :taxpayer_registration_number, :address, presence: true
  validates :code, uniqueness: true
  validates :code, length: { minimum: 3 }, if: proc{|c| c.code.present?}
    validate :company_not_added, on: :create

    before_save :upcase_code
    before_destroy :deletable

    private
  
    def deletable
      errors.add(:base, "The record cannot be deleted")
      throw :abort
    end
  
    def company_not_added
      errors.add(:base, "Sorry, company already exists") if Company.pluck("1 AS one").count > 0
    end

    def upcase_code
      self.code = code.upcase.gsub(" ","").gsub("\t","")
    end

    def strip_field_values
      self.code = code.strip
      self.name = name.strip
      self.taxpayer_registration_number = taxpayer_registration_number.strip
      self.address = address.strip
      self.phone = phone.strip
      self.fax = fax.strip
    end

    def self.display_name
      self.first.name rescue ""
    end

  end
