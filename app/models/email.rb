class Email < ApplicationRecord

  TYPES = [
    ["Account Payable Officer", "Account Payable Officer"],
    ["Sales Officer", "Sales Officer"],
    ["All", "All"]
  ]

  validates :address, :email_type, presence: true
  validates :address, uniqueness: true
  validate :type_available
  
  def self.account_payable_officers
    where("email_type = 'Account Payable Officer' OR email_type = 'All'").select(:address)
  end
  
  private
  
  def type_available
    TYPES.select{ |x| x[1] == email_type }.first.first
  rescue
    errors.add(:email_type, "does not exist!") if email_type.present?
  end

end