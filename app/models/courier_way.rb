class CourierWay < ApplicationRecord
	audited associated_with: :courier, on: :create

  belongs_to :courier
  has_many :courier_units, dependent: :destroy

  accepts_nested_attributes_for :courier_units, allow_destroy: true

  validates :name, presence: true
  validate :shipping_way_available

  before_destroy :delete_tracks

  SHIPPING_WAYS = [
    ["Land", "Land"],
    ["Sea", "Sea"],
    ["Air", "Air"]
  ]
  
  private
  
  def delete_tracks
    audits.destroy_all
  end
  
  def shipping_way_available
    SHIPPING_WAYS.select{ |x| x[1] == name }.first.first
  rescue
    errors.add(:name, "does not exist!") if name.present?
  end
end
