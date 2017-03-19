class Email < ApplicationRecord

  TYPES = [
    ["Account Payable Officer", "Account Payable Officer"],
    ["Sales Officer", "Sales Officer"],
    ["All", "All"]
  ]

  validates :address, :email_type, presence: true
  validates :address, uniqueness: true

end
