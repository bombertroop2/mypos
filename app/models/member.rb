class Member < ApplicationRecord
  before_validation :strip_string_values

  validates :name, :address, :gender, presence: true
  validates :mobile_phone, uniqueness: true, if: proc {|mbr| mbr.mobile_phone.present?}
  validates :email, uniqueness: true, if: proc {|mbr| mbr.email.present?}
  validate :gender_available
  
  before_create :generate_member_id
  
  GENDERS = [
    ["Male", "male"],
    ["Female", "female"],
  ]
  
  private
   
  def strip_string_values
    self.name = name.strip
    self.address = address.strip
    self.email = email.strip
    self.mobile_phone = mobile_phone.delete("_").strip
  end
  
  def gender_available
    GENDERS.select{ |x| x[1] == gender }.first.first
  rescue
    errors.add(:gender, "does not exist!") if gender.present?
  end
  
  def generate_member_id
    self.member_id = Member.select(:member_id).last.member_id.succ rescue "000001"
  end
end
