class Courier < ApplicationRecord
  audited on: [:create, :update]

  has_many :shipments, dependent: :restrict_with_error
  has_one :shipment_relation, -> {select("1 AS one")}, class_name: "Shipment"
  
  before_validation :strip_string_values, :upcase_code
  validates :code, :name, :via, :unit, presence: true
  validates :code, uniqueness: true
  validate :code_not_changed, :via_not_changed, :unit_not_changed, :shipping_way_available, :unit_available
  
  before_destroy :delete_tracks
  
  SHIPPING_WAYS = [
    ["Land", "Land"],
    ["Sea", "Sea"],
    ["Air", "Air"]
  ]
  UNITS = [
    ["Cubic", "Cubic"],
    ["Kilogram", "Kilogram"]
  ]
    
  def code_and_name
    "#{code} - #{name}"
  end

  
  private
  
  def shipping_way_available
    Courier::SHIPPING_WAYS.select{ |x| x[1] == via }.first.first
  rescue
    errors.add(:via, "does not exist!") if via.present?
  end

  def unit_available
    Courier::UNITS.select{ |x| x[1] == unit }.first.first
  rescue
    errors.add(:unit, "does not exist!") if unit.present?
  end
  
  def delete_tracks
    audits.destroy_all
  end
  
  def code_not_changed
    errors.add(:code, "change is not allowed!") if code_changed? && persisted? && shipment_relation.present?
  end

  def via_not_changed
    errors.add(:via, "change is not allowed!") if via_changed? && persisted? && shipment_relation.present?
  end

  def unit_not_changed
    errors.add(:unit, "change is not allowed!") if unit_changed? && persisted? && shipment_relation.present?
  end
  
  def strip_string_values
    self.code = code.strip
  end
  
  def upcase_code
    self.code = code.upcase.gsub(" ","").gsub("\t","")
  end
end
