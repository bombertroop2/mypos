class Courier < ApplicationRecord
  audited on: [:create, :update]

  has_many :shipments, dependent: :restrict_with_error
  has_many :courier_prices, dependent: :destroy
  has_one :shipment_relation, -> {select("1 AS one")}, class_name: "Shipment"

  accepts_nested_attributes_for :courier_prices, allow_destroy: true, reject_if: :status_internal?

  before_validation :strip_string_values, :upcase_code
  validates :code, :name, :via, :unit, :status, presence: true
  validates :code, uniqueness: true
  validate :code_not_changed, :via_not_changed, :unit_not_changed, :shipping_way_available, :unit_available, :status_available, :status_not_changed
  validates :status, uniqueness: {scope: [:via, :unit]}, if: proc{|c| c.status.eql?("Internal")}
  
    before_destroy :delete_tracks
    after_update :remove_prices
  
    SHIPPING_WAYS = [
      ["Land", "Land"],
      ["Sea", "Sea"],
      ["Air", "Air"]
    ]
    UNITS = [
      ["Cubic", "Cubic"],
      ["Kilogram", "Kilogram"]
    ]
    
    STATUSES = [
      ["Internal", "Internal"],
      ["External", "External"]
    ]
     
    def code_and_name
      "#{code} - #{name}"
    end

  
    private
    
    def remove_prices
      courier_prices.destroy_all if status_changed? && status.eql?("Internal")
    end
    
    def status_internal?
      self.status.eql?("Internal")
    end
  
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

    def via_not_changed
      errors.add(:via, "change is not allowed!") if via_changed? && persisted? && shipment_relation.present?
    end

    def unit_not_changed
      errors.add(:unit, "change is not allowed!") if unit_changed? && persisted? && shipment_relation.present?
    end
    
    def status_not_changed
      errors.add(:status, "change is not allowed!") if status_changed? && persisted? && shipment_relation.present?
    end
  
    def strip_string_values
      self.code = code.strip
    end
  
    def upcase_code
      self.code = code.upcase.gsub(" ","").gsub("\t","")
    end
  end
