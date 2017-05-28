class Courier < ApplicationRecord
  before_validation :strip_string_values, :upcase_code
  validates :code, :name, :via, :unit, presence: true
  validates :code, uniqueness: true
  
  SHIPPING_WAYS = [
    ["Land", "Land"],
    ["Sea", "Sea"],
    ["Air", "Air"]
  ]
  UNITS = [
    ["Cubic", "Cubic"],
    ["Kilogram", "Kilogram"]
  ]
  
  private
  
  def strip_string_values
    self.code = code.strip
  end
  
  def upcase_code
    self.code = code.upcase    
  end
end
