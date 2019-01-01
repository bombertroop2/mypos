class CourierUnit < ApplicationRecord
	audited associated_with: :courier_way, on: :create
  belongs_to :courier_way
  has_many :courier_prices, dependent: :destroy
  has_many :packing_lists, dependent: :restrict_with_error

  validates :name, presence: true
  validate :unit_available

  before_destroy :delete_tracks
  
  UNITS = [
    ["Cubic", "Cubic"],
    ["Kilogram", "Kilogram"]
  ]
  
  private
  
  def delete_tracks
    audits.destroy_all
  end
  
  def unit_available
    UNITS.select{ |x| x[1] == name }.first.first
  rescue
    errors.add(:name, "does not exist!") if name.present?
  end
end
