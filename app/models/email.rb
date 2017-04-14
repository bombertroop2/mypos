class Email < ApplicationRecord

  TYPES = [
    ["Account Payable Officer", "Account Payable Officer"],
    ["Sales Officer", "Sales Officer"],
    ["All", "All"]
  ]

  validates :address, :email_type, presence: true
  validates :address, uniqueness: true
  
  def self.account_payable_officers
    where("email_type = 'Account Payable Officer' OR email_type = 'All'").select(:address)
  end

end
