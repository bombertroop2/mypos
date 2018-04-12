class Company < ApplicationRecord
  before_validation :strip_field_values
  
  validates :code, :name, :taxpayer_registration_number, :address, presence: true
  validates :code, uniqueness: true
  
  before_save :upcase_code

  private
  
  def upcase_code
    self.code = code.upcase.gsub(" ","")
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
