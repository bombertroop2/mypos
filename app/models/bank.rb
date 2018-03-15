class Bank < ApplicationRecord
  audited on: [:create, :update]
  TYPES = [
    ["Credit", "Credit"],
    ["Debit", "Debit"]
  ]
  
  has_one :sale_relation, -> {select("1 AS one")}, class_name: "Sale"
  has_many :sales, dependent: :restrict_with_error

  validates :code, :name, :card_type, presence: true
  validate :card_type_available
  validate :code_not_changed, :type_not_changed

  before_save :strip_fields
  before_save :upcase_code
  before_save :remove_space_from_code
  
  before_destroy :delete_tracks
  
  def code_and_name
    "#{code} - #{name} (#{card_type})"
  end
  
  private
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && sale_relation.present?
  end

  def type_not_changed
    errors.add(:card_type, "change is not allowed!") if card_type_changed? && persisted? && sale_relation.present?
  end
  
  def delete_tracks
    audits.destroy_all
  end
  
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
