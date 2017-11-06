class Bank < ApplicationRecord
  TYPES = [
    ["Credit", "Credit"],
    ["Debit", "Debit"]
  ]

  validates :code, :name, :card_type, presence: true
  validate :card_type_available
  
  before_save :strip_fields
  before_save :upcase_code
  before_save :remove_space_from_code
  
  private
  
  def remove_space_from_code
    self.code = code.delete(" ")
  end
  
  def upcase_code    
    self.code = code.upcase
  end
  
  def strip_fields
    self.code = code.strip
    self.name = name.strip
  end

  def card_type_available
    TYPES.select{ |x| x[1] == card_type }.first.first
  rescue
    errors.add(:card_type, "does not exist!") if card_type.present?
  end

end
