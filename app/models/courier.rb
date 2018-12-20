class Courier < ApplicationRecord
  audited on: [:create, :update]

  has_many :shipments, dependent: :restrict_with_error
  has_many :courier_ways, dependent: :destroy
  has_one :shipment_relation, -> {select("1 AS one")}, class_name: "Shipment"

  accepts_nested_attributes_for :courier_ways, allow_destroy: true

  before_validation :strip_string_values, :upcase_code
  validates :code, :name, :status, presence: true
  validates :code, uniqueness: true
  validates :status, uniqueness: true, if: proc{|c| c.status.eql?("Internal")}
    validate :code_not_changed, :status_available, :status_not_changed
  
    before_destroy :delete_tracks
  
    STATUSES = [
      ["Internal", "Internal"],
      ["External", "External"]
    ]
     
    def code_and_name
      "#{code} - #{name}"
    end

  
    private
    
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
