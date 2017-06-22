class UserMenu < ApplicationRecord
  audited associated_with: :user, on: [:create, :update]

  belongs_to :user

  validate :ability_available, :name_available
  
  before_destroy :delete_tracks
  
  private
  
  def delete_tracks
    audits.destroy_all
  end
    
  def ability_available
    User::ABILITIES.select{ |x| x[1] == ability }.first.first
  rescue
    errors.add(:ability, "does not exist!") if ability.present?
  end

  def name_available
    errors.add(:name, "does not exist!") unless AvailableMenu.select("1 AS one").where(active: true, name: name).present?
  end

  
end
