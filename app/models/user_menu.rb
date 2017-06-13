class UserMenu < ApplicationRecord
  belongs_to :user

  validate :ability_available, :name_available
  
  private
  
  def ability_available
    User::ABILITIES.select{ |x| x[1] == ability }.first.first
  rescue
    errors.add(:ability, "does not exist!") if ability.present?
  end

  def name_available
    errors.add(:name, "does not exist!") unless User::MENUS.include? name
  end

  
end
